<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FoxGoSupportCaseTransfer extends Model
{
    protected $table = 'foxgo_support_case_transfers';

    protected $fillable = [
        'case_id',
        'from_department_id',
        'to_department_id',
        'from_admin_id',
        'to_admin_id',
        'reason',
        'internal_note',
        'status_before',
        'status_after',
    ];

    protected $casts = [
        'case_id' => 'integer',
        'from_department_id' => 'integer',
        'to_department_id' => 'integer',
        'from_admin_id' => 'integer',
        'to_admin_id' => 'integer',
    ];


    public function fromDepartment(): BelongsTo
    {
        return $this->belongsTo(FoxGoSupportDepartment::class, 'from_department_id');
    }

    public function toDepartment(): BelongsTo
    {
        return $this->belongsTo(FoxGoSupportDepartment::class, 'to_department_id');
    }

    public function fromAdmin(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'from_admin_id');
    }

    public function toAdmin(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'to_admin_id');
    }

    public function supportCase(): BelongsTo
    {
        return $this->belongsTo(FoxGoSupportCase::class, 'case_id');
    }
}
