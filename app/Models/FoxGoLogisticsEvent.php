<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoLogisticsEvent extends Model
{
    protected $table = 'foxgo_logistics_events';

    protected $fillable = [
        'event_uuid',
        'event_type',
        'mission_type',
        'subject_type',
        'subject_id',
        'order_id',
        'store_id',
        'user_id',
        'delivery_man_id',
        'actor_type',
        'actor_id',
        'source',
        'status_from',
        'status_to',
        'queue_name',
        'correlation_id',
        'occurred_at',
        'payload',
        'metadata',
    ];

    protected $casts = [
        'payload' => 'array',
        'metadata' => 'array',
        'occurred_at' => 'datetime',
    ];
}
