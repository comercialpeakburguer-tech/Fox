<?php

namespace App\Jobs;

use App\Models\FoxGoDispatchOffer;
use App\Services\FoxGo\DispatchOfferService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class FoxGoExpireDispatchOfferJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $offerId;

    public function __construct(int $offerId)
    {
        $this->offerId = $offerId;
        $this->onQueue('logistics');
    }

    public function handle(): void
    {
        $offer = FoxGoDispatchOffer::find($this->offerId);

        if (!$offer || $offer->status !== 'pending') {
            return;
        }

        if ($offer->expires_at && now()->greaterThanOrEqualTo($offer->expires_at)) {
            DispatchOfferService::markTimedOut($offer, 'auto_timeout_job');
        }
    }
}
