<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoStoreItemCatalogProfile extends Model
{
    protected $table = 'foxgo_store_item_catalog_profiles';

    protected $guarded = ['id'];

    protected $casts = [
        'store_id' => 'integer',
        'item_id' => 'integer',
        'store_catalog_category_id' => 'integer',
        'store_catalog_sub_category_id' => 'integer',
        'store_catalog_brand_id' => 'integer',
        'is_enabled' => 'boolean',
    ];

    public function store()
    {
        return $this->belongsTo(Store::class, 'store_id');
    }

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id');
    }
}
