<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoDeliveryPricingRule extends Model
{
    protected $fillable = [
        'rule_code',
        'rule_name',
        'module_id',
        'parcel_category_id',
        'vehicle_id',
        'min_distance_km',
        'max_distance_km',
        'customer_base_fee',
        'customer_per_km_fee',
        'driver_base_payout',
        'driver_per_km_payout',
        'minimum_order_amount',
        'is_enabled',
        'notes',
    ];

    protected $casts = [
        'module_id' => 'integer',
        'parcel_category_id' => 'integer',
        'vehicle_id' => 'integer',
        'min_distance_km' => 'float',
        'max_distance_km' => 'float',
        'customer_base_fee' => 'float',
        'customer_per_km_fee' => 'float',
        'driver_base_payout' => 'float',
        'driver_per_km_payout' => 'float',
        'minimum_order_amount' => 'float',
        'is_enabled' => 'boolean',
    ];
}
