<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoLogisticsStatus extends Model
{
    protected $table = 'foxgo_logistics_statuses';

    protected $fillable = [
        'status_uuid',
        'mission_type',
        'subject_type',
        'subject_id',
        'order_id',
        'store_id',
        'user_id',
        'delivery_man_id',
        'current_offer_id',
        'current_batch_id',
        'last_event_id',
        'operational_status',
        'payment_status',
        'dispatch_status',
        'pickup_status',
        'dropoff_status',
        'support_status',
        'risk_level',
        'driver_earning_amount',
        'distance_to_pickup_km',
        'total_distance_km',
        'eta_to_pickup_seconds',
        'eta_total_seconds',
        'last_event_at',
        'status_updated_at',
        'source',
        'correlation_id',
        'payload',
        'metadata',
    ];

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
