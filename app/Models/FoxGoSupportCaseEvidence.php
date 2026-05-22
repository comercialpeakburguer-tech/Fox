<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FoxGoSupportCaseEvidence extends Model
{
    protected $table = 'foxgo_support_case_evidences';

    protected $fillable = [
        'case_id',
        'uploaded_by_type',
        'uploaded_by_id',
        'evidence_type',
        'file',
        'note',
        'metadata',
    ];

    protected $casts = [
        'case_id' => 'integer',
        'uploaded_by_id' => 'integer',
        'metadata' => 'array',
    ];

    public function supportCase(): BelongsTo
    {
        return $this->belongsTo(FoxGoSupportCase::class, 'case_id');
    }
}
