<?php

namespace App\Services\FoxGo;

use App\Models\FoxGoDispatchOffer;
use App\Models\FoxGoLogisticsEvent;
use App\Models\FoxGoLogisticsStatus;
use Illuminate\Support\Str;

class LogisticsStatusService
{
    public static function upsertStatus(array $data): FoxGoLogisticsStatus
    {
        $payload = $data['payload'] ?? null;
        $metadata = $data['metadata'] ?? null;

        unset($data['payload'], $data['metadata']);

        if (!empty($data['order_id'])) {
            $keys = ['order_id' => $data['order_id']];
        } elseif (!empty($data['subject_type']) && !empty($data['subject_id'])) {
            $keys = [
                'subject_type' => $data['subject_type'],
                'subject_id' => $data['subject_id'],
            ];
        } else {
            $keys = ['status_uuid' => (string) Str::uuid()];
        }

        $values = array_merge([
            'status_uuid' => (string) Str::uuid(),
            'operational_status' => 'created',
            'risk_level' => 'normal',
            'status_updated_at' => now(),
            'source' => 'foxgo_logistics_core',
            'payload' => is_array($payload) ? $payload : null,
            'metadata' => is_array($metadata) ? $metadata : null,
        ], $data);

        $status = FoxGoLogisticsStatus::updateOrCreate($keys, $values);

        LogisticsEventService::record('LOGISTICS_OPERATIONAL_STATUS_UPDATED', [
            'mission_type' => $status->mission_type,
            'subject_type' => 'logistics_status',
            'subject_id' => $status->id,
            'order_id' => $status->order_id,
            'store_id' => $status->store_id,
            'user_id' => $status->user_id,
            'delivery_man_id' => $status->delivery_man_id,
            'source' => $status->source ?: 'foxgo_logistics_core',
            'queue_name' => 'sync',
            'payload' => [
                'status_uuid' => $status->status_uuid,
                'operational_status' => $status->operational_status,
                'dispatch_status' => $status->dispatch_status,
                'risk_level' => $status->risk_level,
                'current_offer_id' => $status->current_offer_id,
            ],
        ]);

        return $status->fresh();
    }

    public static function fromOffer(FoxGoDispatchOffer $offer, array $overrides = []): FoxGoLogisticsStatus
    {
        $event = FoxGoLogisticsEvent::where('subject_type', 'dispatch_offer')
            ->where('subject_id', $offer->id)
            ->orderByDesc('id')
            ->first();

        $dispatchStatus = match ($offer->status) {
            'pending' => 'offer_pending',
            'accepted' => 'offer_accepted',
            'rejected' => 'offer_rejected',
            'timed_out' => 'offer_timed_out',
            'cancelled' => 'offer_cancelled',
            default => 'offer_' . $offer->status,
        };

        $operationalStatus = match ($offer->status) {
            'pending' => 'dispatching',
            'accepted' => 'assigned',
            'rejected', 'timed_out' => 'redispatch_required',
            'cancelled' => 'cancelled',
            default => 'dispatching',
        };

        $riskLevel = in_array($offer->status, ['rejected', 'timed_out'], true) ? 'attention' : 'normal';

        return self::upsertStatus(array_merge([
            'mission_type' => $offer->mission_type,
            'subject_type' => 'dispatch_offer',
            'subject_id' => $offer->id,
            'order_id' => $offer->order_id,
            'store_id' => $offer->store_id,
            'user_id' => $offer->user_id,
            'delivery_man_id' => $offer->delivery_man_id,
            'current_offer_id' => $offer->id,
            'last_event_id' => $event?->id,
            'operational_status' => $operationalStatus,
            'dispatch_status' => $dispatchStatus,
            'risk_level' => $riskLevel,
            'driver_earning_amount' => $offer->driver_earning_amount,
            'distance_to_pickup_km' => $offer->distance_to_pickup_km,
            'total_distance_km' => $offer->total_distance_km,
            'eta_to_pickup_seconds' => $offer->eta_to_pickup_seconds,
            'eta_total_seconds' => $offer->eta_total_seconds,
            'last_event_at' => $event?->occurred_at,
            'status_updated_at' => now(),
            'source' => 'foxgo_logistics_core',
            'payload' => [
                'offer_uuid' => $offer->offer_uuid,
                'offer_type' => $offer->offer_type,
                'offer_status' => $offer->status,
                'expires_at' => optional($offer->expires_at)->toDateTimeString(),
            ],
        ], $overrides));
    }
}
