<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FoxGoSupportDepartment extends Model
{
    protected $table = 'foxgo_support_departments';

    protected $fillable = [
        'name',
        'slug',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function cases(): HasMany
    {
        return $this->hasMany(FoxGoSupportCase::class, 'current_department_id');
    }
}
