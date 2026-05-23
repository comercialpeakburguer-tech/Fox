<?php

namespace App\Models;

use App\CentralLogics\Helpers;
use Illuminate\Database\Eloquent\Model;

class FoxGoReel extends Model
{
    protected $table = 'foxgo_reels';
    protected $guarded = ['id'];

    protected $casts = [
        'status' => 'integer',
        'store_id' => 'integer',
        'item_id' => 'integer',
        'zone_id' => 'integer',
        'module_id' => 'integer',
        'sort_order' => 'integer',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'metadata' => 'array',
    ];

    protected $appends = ['thumbnail_full_url', 'video_full_url', 'store_verified'];

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }

    public function getThumbnailFullUrlAttribute()
    {
        return $this->thumbnail ? Helpers::get_full_url('foxgo-reels/thumbnail', $this->thumbnail, $this->thumbnail_storage ?? 'public') : null;
    }

    public function getVideoFullUrlAttribute()
    {
        return $this->video ? Helpers::get_full_url('foxgo-reels/video', $this->video, $this->video_storage ?? 'public') : null;
    }

    public function getStoreVerifiedAttribute(): bool
    {
        return (bool) ($this->store?->is_verified ?? false);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 1)
            ->where(function ($query) {
                $query->whereNull('starts_at')->orWhere('starts_at', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('ends_at')->orWhere('ends_at', '>=', now());
            });
    }
}
