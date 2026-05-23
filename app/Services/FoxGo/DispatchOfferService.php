<?php

namespace App\Services\FoxGo;

use App\Jobs\FoxGoExpireDispatchOfferJob;
use App\Models\FoxGoDispatchOffer;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class DispatchOfferService
{
    public static function createOffer(array $data): FoxGoDispatchOffer
    {
        $payload = $data['payload'] ?? null;
        $metadata = $data['metadata'] ?? null;
        $ttlSeconds = (int) ($data['ttl_seconds'] ?? 30);
        $autoTimeout = (bool) ($data['auto_timeout'] ?? true);

        unset($data['payload'], $data['metadata'], $data['ttl_seconds'], $data['auto_timeout']);

        $offer = FoxGoDispatchOffer::create(array_merge([
            'offer_uuid' => (string) Str::uuid(),
            'status' => 'pending',
            'offer_type' => 'single',
            'source' => 'foxgo_logistics_core',
            'offered_at' => now(),
            'expires_at' => now()->addSeconds($ttlSeconds),
            'payload' => is_array($payload) ? $payload : null,
            'metadata' => is_array($metadata) ? $metadata : null,
        ], $data));

        LogisticsEventService::record('DISPATCH_OFFER_CREATED', [
            'mission_type' => $offer->mission_type,
            'subject_type' => 'dispatch_offer',
            'subject_id' => $offer->id,
            'order_id' => $offer->order_id,
            'store_id' => $offer->store_id,
            'user_id' => $offer->user_id,
            'delivery_man_id' => $offer->delivery_man_id,
            'source' => $offer->source ?: 'foxgo_logistics_core',
            'queue_name' => 'logistics',
            'payload' => [
                'offer_uuid' => $offer->offer_uuid,
                'offer_type' => $offer->offer_type,
                'status' => $offer->status,
                'expires_at' => optional($offer->expires_at)->toDateTimeString(),
                'driver_earning_amount' => $offer->driver_earning_amount,
            ],
        ]);

        if ($autoTimeout && $ttlSeconds > 0) {
            FoxGoExpireDispatchOfferJob::dispatch($offer->id)
                ->delay(now()->addSeconds($ttlSeconds))
                ->onQueue('logistics');
        }

        return $offer;
    }

    public static function markAccepted(FoxGoDispatchOffer $offer, string $source = 'manual_accept'): FoxGoDispatchOffer
    {
        $lockKey = self::lockKey($offer);

        return Cache::lock($lockKey, 10)->block(3, function () use ($offer, $source) {
            return self::markAcceptedAlreadyLocked($offer, $source);
        });
    }

    public static function markAcceptedAlreadyLocked(FoxGoDispatchOffer $offer, string $source = 'manual_accept_locked'): FoxGoDispatchOffer
    {
        return DB::transaction(function () use ($offer, $source) {
            $fresh = FoxGoDispatchOffer::where('id', $offer->id)->lockForUpdate()->firstOrFail();

            if ($fresh->status !== 'pending') {
                return $fresh;
            }

            $fresh->update([
                'status' => 'accepted',
                'accepted_at' => now(),
                'source' => $fresh->source ?: $source,
            ]);

            $fresh = $fresh->fresh();

            LogisticsEventService::record('DISPATCH_OFFER_ACCEPTED', [
                'mission_type' => $fresh->mission_type,
                'subject_type' => 'dispatch_offer',
                'subject_id' => $fresh->id,
                'order_id' => $fresh->order_id,
                'store_id' => $fresh->store_id,
                'user_id' => $fresh->user_id,
                'delivery_man_id' => $fresh->delivery_man_id,
                'source' => $source,
                'status_from' => 'pending',
                'status_to' => 'accepted',
                'queue_name' => 'logistics',
                'payload' => [
                    'offer_uuid' => $fresh->offer_uuid,
                ],
            ]);

            return $fresh;
        });
    }

    public static function markRejected(FoxGoDispatchOffer $offer, ?string $reason = null, string $source = 'manual_reject'): FoxGoDispatchOffer
    {
        $lockKey = self::lockKey($offer);

        return Cache::lock($lockKey, 10)->block(3, function () use ($offer, $reason, $source) {
            return DB::transaction(function () use ($offer, $reason, $source) {
                $fresh = FoxGoDispatchOffer::where('id', $offer->id)->lockForUpdate()->firstOrFail();

                if ($fresh->status !== 'pending') {
                    return $fresh;
                }

                $fresh->update([
                    'status' => 'rejected',
                    'rejected_at' => now(),
                    'rejection_reason' => $reason,
                ]);

                $fresh = $fresh->fresh();

                LogisticsStatusService::fromOffer($fresh);

                LogisticsEventService::record('DISPATCH_OFFER_REJECTED', [
                    'mission_type' => $fresh->mission_type,
                    'subject_type' => 'dispatch_offer',
                    'subject_id' => $fresh->id,
                    'order_id' => $fresh->order_id,
                    'store_id' => $fresh->store_id,
                    'user_id' => $fresh->user_id,
                    'delivery_man_id' => $fresh->delivery_man_id,
                    'source' => $source,
                    'status_from' => 'pending',
                    'status_to' => 'rejected',
                    'queue_name' => 'logistics',
                    'payload' => [
                        'offer_uuid' => $fresh->offer_uuid,
                        'reason' => $reason,
                    ],
                ]);

                return $fresh;
            });
        });
    }

    public static function markTimedOut(FoxGoDispatchOffer $offer, string $source = 'timeout'): FoxGoDispatchOffer
    {
        $lockKey = self::lockKey($offer);

        return Cache::lock($lockKey, 10)->block(3, function () use ($offer, $source) {
            return DB::transaction(function () use ($offer, $source) {
                $fresh = FoxGoDispatchOffer::where('id', $offer->id)->lockForUpdate()->firstOrFail();

                if ($fresh->status !== 'pending') {
                    return $fresh;
                }

                $fresh->update([
                    'status' => 'timed_out',
                    'timed_out_at' => now(),
                ]);

                $fresh = $fresh->fresh();

                LogisticsStatusService::fromOffer($fresh);

                LogisticsEventService::record('DISPATCH_OFFER_TIMED_OUT', [
                    'mission_type' => $fresh->mission_type,
                    'subject_type' => 'dispatch_offer',
                    'subject_id' => $fresh->id,
                    'order_id' => $fresh->order_id,
                    'store_id' => $fresh->store_id,
                    'user_id' => $fresh->user_id,
                    'delivery_man_id' => $fresh->delivery_man_id,
                    'source' => $source,
                    'status_from' => 'pending',
                    'status_to' => 'timed_out',
                    'queue_name' => 'logistics',
                    'payload' => [
                        'offer_uuid' => $fresh->offer_uuid,
                    ],
                ]);

                return $fresh;
            });
        });
    }

    public static function expirePendingOffers(int $limit = 100): int
    {
        $offers = FoxGoDispatchOffer::where('status', 'pending')
            ->whereNotNull('expires_at')
            ->where('expires_at', '<=', now())
            ->orderBy('expires_at')
            ->limit($limit)
            ->get();

        $count = 0;

        foreach ($offers as $offer) {
            $fresh = self::markTimedOut($offer, 'batch_expire_pending_offers');

            if ($fresh->status === 'timed_out') {
                $count++;
            }
        }

        return $count;
    }

    private static function lockKey(FoxGoDispatchOffer $offer): string
    {
        if (!empty($offer->order_id)) {
            return 'foxgo:dispatch:accept:order:' . $offer->order_id;
        }

        return 'foxgo:dispatch:accept:offer:' . $offer->id;
    }

    public static function markReleasedToAnotherDriver(FoxGoDispatchOffer $offer, ?string $reason = null, string $source = 'driver_release_to_another'): FoxGoDispatchOffer
    {
        return DB::transaction(function () use ($offer, $reason, $source) {
            $fresh = FoxGoDispatchOffer::lockForUpdate()->find($offer->id);

            if (!$fresh) {
                return $offer;
            }

            if (!in_array($fresh->status, ['pending', 'accepted'], true)) {
                return $fresh;
            }

            $from = $fresh->status;

            $fresh->update([
                'status' => 'rejected',
                'rejected_at' => now(),
                'rejection_reason' => $reason ?: 'driver_release_to_another_deliveryman',
            ]);

            $fresh = $fresh->fresh();

            LogisticsStatusService::fromOffer($fresh, [
                'operational_status' => 'redispatch_required',
                'dispatch_status' => 'offer_rejected',
                'support_status' => 'nina_triage',
                'risk_level' => 'attention',
            ]);

            LogisticsEventService::record('DISPATCH_OFFER_RELEASED_TO_ANOTHER_DRIVER', [
                'mission_type' => $fresh->mission_type,
                'subject_type' => 'dispatch_offer',
                'subject_id' => $fresh->id,
                'order_id' => $fresh->order_id,
                'store_id' => $fresh->store_id,
                'user_id' => $fresh->user_id,
                'delivery_man_id' => $fresh->delivery_man_id,
                'actor_type' => 'delivery_man',
                'actor_id' => $fresh->delivery_man_id,
                'source' => $source,
                'status_from' => $from,
                'status_to' => 'rejected',
                'queue_name' => 'logistics',
                'payload' => [
                    'reason' => $reason ?: 'driver_release_to_another_deliveryman',
                    'label' => 'Passar para outro entregador',
                    'no_customer_order_cancel' => true,
                ],
            ]);

            return $fresh;
        });
    }
}
