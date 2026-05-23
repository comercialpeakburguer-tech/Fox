<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Item;
use Illuminate\Http\Request;

class FoxGoInventoryController extends Controller
{
    public function vendorLowStockItems(Request $request)
    {
        $store = $request->vendor?->stores[0] ?? null;

        if (!$store) {
            return response()->json([
                'errors' => [
                    ['code' => 'store', 'message' => translate('messages.not_found')],
                ],
            ], 404);
        }

        $limit = (int) ($request->limit ?? 20);
        $offset = (int) ($request->offset ?? 1);

        $items = Item::withoutGlobalScope(\App\Scopes\StoreScope::class)
            ->where('store_id', $store->id)
            ->whereNotNull('low_stock_alert_quantity')
            ->whereColumn('stock', '<=', 'low_stock_alert_quantity')
            ->latest()
            ->paginate($limit, ['*'], 'page', $offset);

        return response()->json([
            'total_size' => $items->total(),
            'limit' => $limit,
            'offset' => $offset,
            'items' => $items->items(),
        ], 200);
    }
}
