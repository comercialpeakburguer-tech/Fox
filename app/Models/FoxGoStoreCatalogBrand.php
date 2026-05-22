<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class FoxGoStoreCatalogBrand extends Model
{
    protected $table = 'foxgo_store_catalog_brands';

protected $fillable = [
        'store_id',
        'module_id',
        'name',
        'slug',
        'status',
        'is_enabled',
    ];

    protected $casts = [
        'store_id' => 'integer',
        'module_id' => 'integer',
        'status' => 'boolean',
        'is_enabled' => 'boolean',
    ];

    protected static function booted(): void
    {
        static::saving(function ($model) {
            if (!$model->slug && $model->name) {
                $model->slug = Str::slug($model->name);
            }
        });
    }
}
