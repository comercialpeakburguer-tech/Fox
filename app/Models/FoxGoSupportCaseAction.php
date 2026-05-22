<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FoxGoSupportCaseAction extends Model
{
    protected $table = 'foxgo_support_case_actions';

    protected $fillable = [
        'case_id',
        'admin_id',
        'department_id',
        'action_type',
        'description',
        'old_value',
        'new_value',
        'metadata',
    ];

    protected $casts = [
        'case_id' => 'integer',
        'admin_id' => 'integer',
        'department_id' => 'integer',
        'metadata' => 'array',
    ];

    public function supportCase(): BelongsTo
    {
        return $this->belongsTo(FoxGoSupportCase::class, 'case_id');
    }
}
