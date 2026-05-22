<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoDeliveryDispatchRule extends Model
{
    protected $fillable = [
        'rule_code',
        'rule_name',
        'module_id',
        'parcel_category_id',
        'volume_label',
        'max_weight_kg',
        'max_distance_km',
        'primary_vehicle_id',
        'fallback_vehicle_id',
        'priority_order',
        'bike_allowed',
        'market_block_bike',
        'requires_manual_review',
        'is_enabled',
        'notes',
    ];

    protected $casts = [
        'module_id' => 'integer',
        'parcel_category_id' => 'integer',
        'max_weight_kg' => 'float',
        'max_distance_km' => 'float',
        'primary_vehicle_id' => 'integer',
        'fallback_vehicle_id' => 'integer',
        'priority_order' => 'integer',
        'bike_allowed' => 'boolean',
        'market_block_bike' => 'boolean',
        'requires_manual_review' => 'boolean',
        'is_enabled' => 'boolean',
    ];
}
