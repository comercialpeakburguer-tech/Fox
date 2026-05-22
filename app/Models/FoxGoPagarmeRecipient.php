<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoPagarmeRecipient extends Model
{
    protected $table = 'foxgo_pagarme_recipients';

    protected $fillable = [
        'owner_type',
        'owner_id',
        'store_id',
        'vendor_id',
        'delivery_man_id',
        'environment',
        'recipient_id',
        'status',
        'legal_name',
        'document_type',
        'document_last4',
        'bank_code',
        'bank_account_last4',
        'transfer_enabled',
        'split_enabled',
        'last_sync_at',
        'metadata',
        'error_message',
    ];

    protected $casts = [
        'transfer_enabled' => 'boolean',
        'split_enabled' => 'boolean',
        'last_sync_at' => 'datetime',
        'metadata' => 'array',
    ];
}