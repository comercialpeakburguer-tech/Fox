<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FoxGoSupportAdminDepartment extends Model
{
    protected $table = 'foxgo_support_admin_departments';

    protected $fillable = [
        'admin_id',
        'department_id',
        'role_in_department',
        'can_view_financial_context',
        'can_handle_refund',
        'can_handle_repasses',
        'is_active',
    ];

    protected $casts = [
        'can_view_financial_context' => 'boolean',
        'can_handle_refund' => 'boolean',
        'can_handle_repasses' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function admin(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'admin_id');
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(FoxGoSupportDepartment::class, 'department_id');
    }
}
