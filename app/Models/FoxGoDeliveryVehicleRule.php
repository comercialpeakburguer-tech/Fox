<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoDeliveryVehicleRule extends Model
{
    protected $fillable = [
        'vehicle_id',
        'vehicle_type',
        'vehicle_name',
        'max_distance_km',
        'max_weight_kg',
        'max_volume_label',
        'allowed_module_ids',
        'blocked_module_ids',
        'is_delivery',
        'is_enabled',
        'notes',
    ];

    protected $casts = [
        'max_distance_km' => 'float',
        'max_weight_kg' => 'float',
        'allowed_module_ids' => 'array',
        'blocked_module_ids' => 'array',
        'is_delivery' => 'boolean',
        'is_enabled' => 'boolean',
    ];
}
