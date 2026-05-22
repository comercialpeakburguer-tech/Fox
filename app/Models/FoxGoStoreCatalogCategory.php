<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class FoxGoStoreCatalogCategory extends Model
{
    protected $table = 'foxgo_store_catalog_categories';

protected $fillable = [
        'store_id',
        'module_id',
        'parent_id',
        'name',
        'slug',
        'position',
        'sort_order',
        'status',
        'is_enabled',
    ];

    protected $casts = [
        'store_id' => 'integer',
        'module_id' => 'integer',
        'parent_id' => 'integer',
        'position' => 'integer',
        'sort_order' => 'integer',
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
