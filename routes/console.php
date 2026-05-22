<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;
use App\Services\FoxGo\DispatchOfferService;

/*
|--------------------------------------------------------------------------
| Console Routes
|--------------------------------------------------------------------------
|
| This file is where you may define all of your Closure based console
| commands. Each Closure is bound to a command instance allowing a
| simple approach to interacting with each command's IO methods.
|
*/

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Fox GO - recuperação automática de splits Stripe Connect pendentes
Schedule::command('foxgo:recover-stripe-splits --days=30 --limit=50')
    ->everyFiveMinutes()
    ->withoutOverlapping(10)
    ->appendOutputTo(storage_path('logs/foxgo_recover_stripe_splits.log'));

// Fox GO - repasses nativos 6amMart via Laravel Scheduler - INICIO
// Usa SOMENTE os comandos nativos do 6amMart: store:disbursement e dm:disbursement.
// A agenda é lida de business_settings a cada execução do schedule:run,
// então alterações feitas no painel refletem automaticamente sem cron estático no host.
try {
    $settings = \Illuminate\Support\Facades\DB::table('business_settings')
        ->whereIn('key', [
            'disbursement_type',
            'store_disbursement_time_period',
            'store_disbursement_week_start',
            'store_disbursement_create_time',
            'dm_disbursement_time_period',
            'dm_disbursement_week_start',
            'dm_disbursement_create_time',
        ])
        ->pluck('value', 'key')
        ->toArray();

    $foxgoBuildDisbursementCron = function (string $prefix) use ($settings) {
        $period = $settings[$prefix . '_disbursement_time_period'] ?? 'daily';
        $weekDay = $settings[$prefix . '_disbursement_week_start'] ?? 'monday';
        $time = $settings[$prefix . '_disbursement_create_time'] ?? '08:00';

        if (!preg_match('/^\d{2}:\d{2}$/', $time)) {
            $time = '08:00';
        }

        [$hour, $minute] = explode(':', $time);

        $days = [
            'sunday' => 0,
            'monday' => 1,
            'tuesday' => 2,
            'wednesday' => 3,
            'thursday' => 4,
            'friday' => 5,
            'saturday' => 6,
        ];

        if ($period === 'weekly') {
            $day = $days[$weekDay] ?? 1;
            return "{$minute} {$hour} * * {$day}";
        }

        if ($period === 'monthly') {
            return "{$minute} {$hour} 28-31 * *";
        }

        return "{$minute} {$hour} * * *";
    };

    if (($settings['disbursement_type'] ?? 'manual') === 'automated') {
        Schedule::command('store:disbursement')
            ->cron($foxgoBuildDisbursementCron('store'))
            ->withoutOverlapping(120)
            ->appendOutputTo(storage_path('logs/foxgo_store_disbursement.log'));

        Schedule::command('dm:disbursement')
            ->cron($foxgoBuildDisbursementCron('dm'))
            ->withoutOverlapping(120)
            ->appendOutputTo(storage_path('logs/foxgo_dm_disbursement.log'));
    }
} catch (\Throwable $exception) {
    logger()->error('Fox GO repasses nativos 6amMart scheduler erro', [
        'message' => $exception->getMessage(),
    ]);
}
// Fox GO - repasses nativos 6amMart via Laravel Scheduler - FIM


// Fox GO Logistics: expire pending dispatch offers fallback.
// Fallback seguro: expira offers vencidas que ficaram pending caso algum job individual não rode.
Schedule::call(function () {
    DispatchOfferService::expirePendingOffers(200);
})
    ->name('foxgo-logistics-expire-dispatch-offers')
    ->everyMinute()
    ->withoutOverlapping()
    ->description('foxgo-logistics-expire-dispatch-offers');

