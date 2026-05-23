<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoDispatchOffer extends Model
{
    protected $table = 'foxgo_dispatch_offers';

    protected $fillable = [
        'offer_uuid',
        'mission_type',
        'offer_type',
        'order_id',
        'store_id',
        'user_id',
        'delivery_man_id',
        'status',
        'score',
        'distance_to_pickup_km',
        'total_distance_km',
        'eta_to_pickup_seconds',
        'eta_total_seconds',
        'driver_earning_amount',
        'extra_earning_amount',
        'extra_distance_km',
        'extra_eta_seconds',
        'batch_id',
        'previous_order_id',
        'sequence',
        'offered_at',
        'expires_at',
        'accepted_at',
        'rejected_at',
        'timed_out_at',
        'cancelled_at',
        'rejection_reason',
        'source',
        'correlation_id',
        'payload',
        'metadata',
    ];

    protected $casts = [
        'score' => 'decimal:4',
        'distance_to_pickup_km' => 'decimal:3',
        'total_distance_km' => 'decimal:3',
        'driver_earning_amount' => 'decimal:2',
        'extra_earning_amount' => 'decimal:2',
        'extra_distance_km' => 'decimal:3',
        'payload' => 'array',
        'metadata' => 'array',
        'offered_at' => 'datetime',
        'expires_at' => 'datetime',
        'accepted_at' => 'datetime',
        'rejected_at' => 'datetime',
        'timed_out_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];
}
