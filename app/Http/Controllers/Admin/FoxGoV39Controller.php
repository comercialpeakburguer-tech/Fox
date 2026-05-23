<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Store;
use Illuminate\Http\Request;

class FoxGoV39Controller extends Controller
{
    public function storeVerificationStatus(Request $request, Store $store)
    {
        $request->validate([
            'is_verified' => 'required|boolean',
        ]);

        $store->is_verified = (bool) $request->is_verified;
        $store->verified_at = $store->is_verified ? now() : null;
        $store->save();

        return response()->json([
            'message' => translate('messages.status_updated'),
            'store_id' => $store->id,
            'is_verified' => (bool) $store->is_verified,
            'verified_at' => optional($store->verified_at)->toDateTimeString(),
        ]);
    }
}
