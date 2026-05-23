<?php

namespace App\Services\FoxGo;

use App\Models\FoxGoLogisticsEvent;
use Illuminate\Support\Str;

class LogisticsEventService
{
    public static function record(string $eventType, array $data = []): FoxGoLogisticsEvent
    {
        $payload = $data['payload'] ?? null;
        $metadata = $data['metadata'] ?? null;

        unset($data['payload'], $data['metadata']);

        return FoxGoLogisticsEvent::create(array_merge([
            'event_uuid' => (string) Str::uuid(),
            'event_type' => $eventType,
            'occurred_at' => now(),
            'source' => 'foxgo_logistics_core',
            'payload' => is_array($payload) ? $payload : null,
            'metadata' => is_array($metadata) ? $metadata : null,
        ], $data));
    }
}
