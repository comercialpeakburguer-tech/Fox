<?php

namespace App\Http\Controllers\Api\V1;

use App\CentralLogics\Helpers;
use App\Http\Controllers\Controller;
use App\Models\FoxGoReel;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class FoxGoReelController extends Controller
{
    public function index(Request $request)
    {
        $limit = (int) ($request->limit ?? 20);
        $offset = (int) ($request->offset ?? 1);

        $reels = FoxGoReel::with(['store:id,name,logo,cover_photo,is_verified', 'item:id,name,image,price,discount,discount_type,store_id'])
            ->active()
            ->when($request->store_id, fn ($query) => $query->where('store_id', $request->store_id))
            ->when($request->module_id, fn ($query) => $query->where('module_id', $request->module_id))
            ->when($request->zone_id, fn ($query) => $query->where('zone_id', $request->zone_id))
            ->orderBy('sort_order')
            ->latest()
            ->paginate($limit, ['*'], 'page', $offset);

        return response()->json([
            'total_size' => $reels->total(),
            'limit' => $limit,
            'offset' => $offset,
            'reels' => $reels->items(),
        ], 200);
    }

    public function vendorList(Request $request)
    {
        $store = $request->vendor?->stores[0] ?? null;
        if (!$store) {
            return response()->json(['errors' => [['code' => 'store', 'message' => translate('messages.not_found')]]], 404);
        }

        $limit = (int) ($request->limit ?? 20);
        $offset = (int) ($request->offset ?? 1);

        $reels = FoxGoReel::where('store_id', $store->id)
            ->with(['item:id,name,image,price,discount,discount_type,store_id'])
            ->latest()
            ->paginate($limit, ['*'], 'page', $offset);

        return response()->json([
            'total_size' => $reels->total(),
            'limit' => $limit,
            'offset' => $offset,
            'reels' => $reels->items(),
        ], 200);
    }

    public function vendorStore(Request $request)
    {
        $store = $request->vendor?->stores[0] ?? null;
        if (!$store) {
            return response()->json(['errors' => [['code' => 'store', 'message' => translate('messages.not_found')]]], 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'nullable|string|max:191',
            'description' => 'nullable|string',
            'item_id' => 'nullable|integer',
            'thumbnail' => 'nullable|file|mimes:' . IMAGE_FORMAT_FOR_VALIDATION . '|max:' . MAX_FILE_SIZE * 1024,
            'video' => 'nullable|file|mimes:mp4,webm,ogg,mov|max:51200',
            'video_link' => 'nullable|string|max:1000',
            'status' => 'nullable|boolean',
            'sort_order' => 'nullable|integer',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        if (!$request->hasFile('video') && !$request->video_link) {
            return response()->json(['errors' => [['code' => 'video', 'message' => translate('messages.video_or_video_link_required')]]], 403);
        }

        $reel = FoxGoReel::create([
            'store_id' => $store->id,
            'item_id' => $request->item_id,
            'zone_id' => $store->zone_id,
            'module_id' => $store->module_id,
            'title' => $request->title,
            'description' => $request->description,
            'thumbnail' => $request->hasFile('thumbnail') ? Helpers::upload('foxgo-reels/thumbnail/', 'png', $request->file('thumbnail')) : null,
            'thumbnail_storage' => $request->hasFile('thumbnail') ? Helpers::getDisk() : 'public',
            'video' => $request->hasFile('video') ? Helpers::upload('foxgo-reels/video/', 'mp4', $request->file('video')) : null,
            'video_storage' => $request->hasFile('video') ? Helpers::getDisk() : 'public',
            'video_link' => $request->video_link,
            'status' => (int) ($request->status ?? 1),
            'sort_order' => (int) ($request->sort_order ?? 0),
            'starts_at' => $request->starts_at,
            'ends_at' => $request->ends_at,
        ]);

        return response()->json([
            'message' => translate('messages.successfully_added'),
            'reel' => $reel->fresh(),
        ], 200);
    }

    public function vendorStatus(Request $request)
    {
        $store = $request->vendor?->stores[0] ?? null;
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer',
            'status' => 'required|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => Helpers::error_processor($validator)], 403);
        }

        $reel = FoxGoReel::where('store_id', $store?->id)->find($request->id);
        if (!$reel) {
            return response()->json(['errors' => [['code' => 'reel', 'message' => translate('messages.not_found')]]], 404);
        }

        $reel->status = (int) $request->status;
        $reel->save();

        return response()->json(['message' => translate('messages.status_updated')], 200);
    }
}
