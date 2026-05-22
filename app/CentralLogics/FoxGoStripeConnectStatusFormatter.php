<?php

namespace App\CentralLogics;

class FoxGoStripeConnectStatusFormatter
{
    public static function summarize(array $data): array
    {
        $externalAccounts = [];

        foreach (($data['external_accounts']['data'] ?? []) as $external) {
            $externalAccounts[] = [
                'id' => $external['id'] ?? null,
                'object' => $external['object'] ?? null,
                'bank_name' => $external['bank_name'] ?? null,
                'country' => $external['country'] ?? null,
                'currency' => $external['currency'] ?? null,
                'last4' => $external['last4'] ?? null,
                'status' => $external['status'] ?? null,
                'default_for_currency' => $external['default_for_currency'] ?? null,
            ];
        }

        return [
            'account_id' => $data['id'] ?? null,
            'type' => $data['type'] ?? null,
            'country' => $data['country'] ?? null,
            'default_currency' => $data['default_currency'] ?? null,
            'business_type' => $data['business_type'] ?? null,
            'charges_enabled' => !empty($data['charges_enabled']) ? 1 : 0,
            'payouts_enabled' => !empty($data['payouts_enabled']) ? 1 : 0,
            'details_submitted' => !empty($data['details_submitted']) ? 1 : 0,
            'capabilities' => $data['capabilities'] ?? [],
            'requirements' => [
                'disabled_reason' => $data['requirements']['disabled_reason'] ?? null,
                'currently_due' => array_values($data['requirements']['currently_due'] ?? []),
                'eventually_due' => array_values($data['requirements']['eventually_due'] ?? []),
                'past_due' => array_values($data['requirements']['past_due'] ?? []),
                'pending_verification' => array_values($data['requirements']['pending_verification'] ?? []),
                'errors' => array_values($data['requirements']['errors'] ?? []),
            ],
            'future_requirements' => [
                'currently_due' => array_values($data['future_requirements']['currently_due'] ?? []),
                'eventually_due' => array_values($data['future_requirements']['eventually_due'] ?? []),
                'past_due' => array_values($data['future_requirements']['past_due'] ?? []),
                'pending_verification' => array_values($data['future_requirements']['pending_verification'] ?? []),
                'errors' => array_values($data['future_requirements']['errors'] ?? []),
            ],
            'external_accounts' => $externalAccounts,
            'synced_at' => date('c'),
        ];
    }

    public static function statusFromSummary(array $summary): string
    {
        $requirements = $summary['requirements'] ?? [];
        $capabilities = $summary['capabilities'] ?? [];

        $charges = (int)($summary['charges_enabled'] ?? 0) === 1;
        $payouts = (int)($summary['payouts_enabled'] ?? 0) === 1;
        $details = (int)($summary['details_submitted'] ?? 0) === 1;
        $cardActive = ($capabilities['card_payments'] ?? null) === 'active';
        $transfersActive = ($capabilities['transfers'] ?? null) === 'active';

        $hasErrors = !empty($requirements['errors']);
        $hasDisabledReason = !empty($requirements['disabled_reason']);
        $hasPastDue = !empty($requirements['past_due']);
        $hasCurrentlyDue = !empty($requirements['currently_due']);
        $hasPendingVerification = !empty($requirements['pending_verification']);

        if ($charges && $payouts && $details && $cardActive && $transfersActive && !$hasErrors && !$hasDisabledReason && !$hasPastDue && !$hasCurrentlyDue && !$hasPendingVerification) {
            return 'active';
        }

        if (($requirements['disabled_reason'] ?? null) === 'requirements.pending_verification' || $hasPendingVerification) {
            return 'pending_verification';
        }

        if ($hasErrors || $hasDisabledReason || $hasPastDue) {
            return 'verification_error';
        }

        return 'onboarding';
    }

    public static function applyToVendor($vendor, array $data): void
    {
        $summary = self::summarize($data);

        $vendor->stripe_charges_enabled = (int) $summary['charges_enabled'];
        $vendor->stripe_payouts_enabled = (int) $summary['payouts_enabled'];
        $vendor->stripe_details_submitted = (int) $summary['details_submitted'];
        $vendor->stripe_requirements_due = json_encode($summary, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $vendor->stripe_connect_status = self::statusFromSummary($summary);

        if ($vendor->stripe_connect_status === 'active' && empty($vendor->stripe_onboarding_completed_at)) {
            $vendor->stripe_onboarding_completed_at = now();
        }
    }
}
