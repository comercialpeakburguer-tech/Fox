<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FoxGoItemLogisticsProfile extends Model
{
    protected $table = 'foxgo_item_logistics_profiles';

    protected $guarded = ['id'];

    protected $casts = [
        'item_id' => 'integer',
        'category_id' => 'integer',
        'module_id' => 'integer',
        'weight_kg' => 'float',
        'length_cm' => 'float',
        'width_cm' => 'float',
        'height_cm' => 'float',
        'bike_allowed' => 'boolean',
        'motorcycle_allowed' => 'boolean',
        'car_required' => 'boolean',
        'utility_required' => 'boolean',
        'van_required' => 'boolean',
        'manual_review_required' => 'boolean',
        'is_enabled' => 'boolean',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class, 'item_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    public function module()
    {
        return $this->belongsTo(Module::class, 'module_id');
    }
}
