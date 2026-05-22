<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FoxGoSupportCase extends Model
{
    protected $table = 'foxgo_support_cases';

    protected $fillable = [
        'protocol',
        'order_id',
        'customer_id',
        'store_id',
        'vendor_id',
        'delivery_man_id',
        'conversation_id',
        'opened_by_type',
        'opened_by_id',
        'current_department_id',
        'assigned_admin_id',
        'status',
        'priority',
        'reason',
        'subject',
        'description',
        'sla_due_at',
        'closed_at',
        'closed_by',
        'final_decision',
        'loss_responsible_party',
    ];

    protected $casts = [
        'order_id' => 'integer',
        'customer_id' => 'integer',
        'store_id' => 'integer',
        'vendor_id' => 'integer',
        'delivery_man_id' => 'integer',
        'conversation_id' => 'integer',
        'opened_by_id' => 'integer',
        'current_department_id' => 'integer',
        'assigned_admin_id' => 'integer',
        'closed_by' => 'integer',
        'sla_due_at' => 'datetime',
        'closed_at' => 'datetime',
    ];

    public function department(): BelongsTo
    {
        return $this->belongsTo(FoxGoSupportDepartment::class, 'current_department_id');
    }

    public function assignedAdmin(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'assigned_admin_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class, 'store_id');
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class, 'vendor_id');
    }

    public function deliveryMan(): BelongsTo
    {
        return $this->belongsTo(DeliveryMan::class, 'delivery_man_id');
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class, 'conversation_id');
    }

    public function transfers(): HasMany
    {
        return $this->hasMany(FoxGoSupportCaseTransfer::class, 'case_id');
    }

    public function evidences(): HasMany
    {
        return $this->hasMany(FoxGoSupportCaseEvidence::class, 'case_id');
    }

    public function actions(): HasMany
    {
        return $this->hasMany(FoxGoSupportCaseAction::class, 'case_id');
    }
}
