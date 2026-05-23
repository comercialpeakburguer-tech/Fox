<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoLogisticsStatus extends Model
{
    protected $table = 'foxgo_logistics_statuses';

    protected $guarded = ['id'];

    protected $casts = [
        'payload' => 'array',
        'metadata' => 'array',
        'driver_earning_amount' => 'decimal:2',
        'distance_to_pickup_km' => 'decimal:3',
        'total_distance_km' => 'decimal:3',
        'last_event_at' => 'datetime',
        'status_updated_at' => 'datetime',
    ];
}
