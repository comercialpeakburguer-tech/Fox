<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FoxGoReel;
use App\Models\Item;
use App\Models\Store;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;

class FoxGoV39Controller extends Controller
{
    public function index()
    {
        $tables = [
            'foxgo_reels' => Schema::hasTable('foxgo_reels'),
            'user_files' => Schema::hasTable('user_files'),
            'items' => Schema::hasTable('items'),
            'stores' => Schema::hasTable('stores'),
        ];

        $columns = [
            'items.video' => Schema::hasColumn('items', 'video'),
            'items.video_link' => Schema::hasColumn('items', 'video_link'),
            'items.low_stock_alert_quantity' => Schema::hasColumn('items', 'low_stock_alert_quantity'),
            'stores.is_verified' => Schema::hasColumn('stores', 'is_verified'),
            'stores.verified_at' => Schema::hasColumn('stores', 'verified_at'),
        ];

        $uris = collect(Route::getRoutes())->map(fn ($route) => $route->uri())->values();

        $apiRoutes = [
            'api/v1/app-download-section' => $uris->contains('api/v1/app-download-section'),
            'api/v1/reels' => $uris->contains('api/v1/reels'),
            'api/v1/delivery-man/new-earning-report' => $uris->contains('api/v1/delivery-man/new-earning-report'),
            'api/v1/vendor/earning-report' => $uris->contains('api/v1/vendor/earning-report'),
            'api/v1/vendor/inventory/low-stock' => $uris->contains('api/v1/vendor/inventory/low-stock'),
            'api/v1/vendor/reels' => $uris->contains('api/v1/vendor/reels'),
            'api/v1/customer/saved-files' => $uris->contains('api/v1/customer/saved-files'),
        ];

        $reels = Schema::hasTable('foxgo_reels')
            ? FoxGoReel::with(['store:id,name,logo,is_verified', 'item:id,name,image,store_id'])->latest()->paginate(20)
            : new LengthAwarePaginator([], 0, 20);

        $stores = Schema::hasTable('stores')
            ? Store::select('id', 'name', 'is_verified', 'verified_at')->orderBy('name')->limit(300)->get()
            : collect();

        $stats = [
            'reels_total' => Schema::hasTable('foxgo_reels') ? FoxGoReel::count() : 0,
            'reels_active' => Schema::hasTable('foxgo_reels') ? FoxGoReel::where('status', 1)->count() : 0,
            'verified_stores' => Schema::hasColumn('stores', 'is_verified') ? Store::where('is_verified', 1)->count() : 0,
            'low_stock_items' => Schema::hasColumn('items', 'low_stock_alert_quantity')
                ? Item::whereNotNull('low_stock_alert_quantity')->whereColumn('stock', '<=', 'low_stock_alert_quantity')->count()
                : 0,
        ];

        return view('admin-views.foxgo-v39.index', compact('tables', 'columns', 'apiRoutes', 'reels', 'stores', 'stats'));
    }

    public function reelsStore(Request $request)
    {
        $request->validate([
            'store_id' => 'required|exists:stores,id',
            'item_id' => 'nullable|integer',
            'title' => 'nullable|string|max:191',
            'description' => 'nullable|string|max:1000',
            'video_link' => 'required|string|max:1000',
            'sort_order' => 'nullable|integer|min:0',
            'status' => 'nullable|boolean',
        ]);

        FoxGoReel::create([
            'store_id' => $request->store_id,
            'item_id' => $request->item_id ?: null,
            'title' => $request->title,
            'description' => $request->description,
            'video_link' => $request->video_link,
            'status' => $request->boolean('status'),
            'sort_order' => (int) ($request->sort_order ?? 0),
        ]);

        Toastr::success('Reel criado com sucesso.');
        return back();
    }

    public function reelStatus(Request $request, FoxGoReel $reel)
    {
        $request->validate([
            'status' => 'required|boolean',
        ]);

        $reel->status = (int) $request->status;
        $reel->save();

        Toastr::success('Status do Reel atualizado.');
        return back();
    }

    public function reelDestroy(FoxGoReel $reel)
    {
        $reel->delete();

        Toastr::success('Reel removido.');
        return back();
    }

    public function storeVerificationStatus(Request $request, Store $store)
    {
        $request->validate([
            'is_verified' => 'required|boolean',
        ]);

        $store->is_verified = (bool) $request->is_verified;
        $store->verified_at = $store->is_verified ? now() : null;
        $store->save();

        if ($request->expectsJson()) {
            return response()->json([
                'message' => translate('messages.status_updated'),
                'store_id' => $store->id,
                'is_verified' => (bool) $store->is_verified,
                'verified_at' => optional($store->verified_at)->toDateTimeString(),
            ]);
        }

        Toastr::success('Status de loja verificada atualizado.');
        return back();
    }
}
