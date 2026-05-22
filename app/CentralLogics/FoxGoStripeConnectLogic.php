<?php

namespace App\CentralLogics;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Stripe\Stripe;
use Stripe\PaymentIntent;
use Stripe\Transfer;
use Throwable;

class FoxGoStripeConnectLogic
{
    public static function executeForOrder(int $orderId): array
    {
        try {
            $order = DB::table('orders')->where('id', $orderId)->first();

            if (!$order) {
                return self::skip('order_not_found', $orderId);
            }

            if (($order->payment_method ?? null) !== 'stripe') {
                return self::skip('not_stripe_order', $orderId);
            }

            if (($order->payment_status ?? null) !== 'paid') {
                return self::skip('payment_not_paid', $orderId);
            }

            if (($order->order_status ?? null) !== 'delivered') {
                return self::skip('order_not_delivered', $orderId);
            }

            if (Schema::hasColumn('orders', 'stripe_transfer_id') && !empty($order->stripe_transfer_id)) {
                return self::skip('transfer_already_exists', $orderId, [
                    'stripe_transfer_id' => $order->stripe_transfer_id,
                ]);
            }

            $tx = DB::table('order_transactions')->where('order_id', $orderId)->first();

            if (!$tx) {
                return self::skip('order_transaction_not_found', $orderId);
            }

            $storeAmountCents = self::moneyToCents($tx->store_amount ?? 0);

            if ($storeAmountCents <= 0) {
                return self::skip('store_amount_invalid', $orderId, [
                    'store_amount' => $tx->store_amount ?? null,
                ]);
            }

            $store = DB::table('stores')->where('id', $order->store_id)->first();

            if (!$store) {
                return self::skip('store_not_found', $orderId);
            }

            $vendor = DB::table('vendors')->where('id', $store->vendor_id)->first();

            if (!$vendor) {
                return self::skip('vendor_not_found', $orderId);
            }

            if (empty($vendor->stripe_account_id)) {
                return self::skip('vendor_without_stripe_account', $orderId, [
                    'vendor_id' => $vendor->id ?? null,
                ]);
            }

            if (
                (int)($vendor->stripe_charges_enabled ?? 0) !== 1 ||
                (int)($vendor->stripe_payouts_enabled ?? 0) !== 1 ||
                (int)($vendor->stripe_details_submitted ?? 0) !== 1
            ) {
                return self::skip('vendor_connect_not_active', $orderId, [
                    'vendor_id' => $vendor->id ?? null,
                    'stripe_account_id' => $vendor->stripe_account_id ?? null,
                    'stripe_charges_enabled' => $vendor->stripe_charges_enabled ?? null,
                    'stripe_payouts_enabled' => $vendor->stripe_payouts_enabled ?? null,
                    'stripe_details_submitted' => $vendor->stripe_details_submitted ?? null,
                ]);
            }

            $apiKey = self::stripeApiKey();

            if (!$apiKey) {
                return self::skip('stripe_api_key_missing', $orderId);
            }

            Stripe::setApiKey($apiKey);

            $paymentIntentId = self::paymentIntentId($order, $orderId);
            $chargeId = null;

            if ($paymentIntentId) {
                try {
                    $pi = PaymentIntent::retrieve([
                        'id' => $paymentIntentId,
                        'expand' => ['latest_charge'],
                    ]);

                    if (isset($pi->latest_charge)) {
                        if (is_string($pi->latest_charge)) {
                            $chargeId = $pi->latest_charge;
                        } elseif (isset($pi->latest_charge->id)) {
                            $chargeId = $pi->latest_charge->id;
                        }
                    }
                } catch (Throwable $e) {
                    info('FoxGoStripeConnect: falha ao recuperar PaymentIntent order_id=' . $orderId . ' erro=' . $e->getMessage());
                }
            }

            $payload = [
                'amount' => $storeAmountCents,
                'currency' => 'brl',
                'destination' => $vendor->stripe_account_id,
                'transfer_group' => 'ORDER_' . $orderId,
                'metadata' => [
                    'foxgo_order_id' => (string)$orderId,
                    'foxgo_order_transaction_id' => (string)$tx->id,
                    'foxgo_store_id' => (string)$store->id,
                    'foxgo_vendor_id' => (string)$vendor->id,
                    'foxgo_reason' => 'auto_store_amount_after_delivery',
                ],
            ];

            if ($chargeId) {
                $payload['source_transaction'] = $chargeId;
            }

            $transfer = Transfer::create($payload, [
                'idempotency_key' => 'foxgo_auto_order_' . $orderId . '_store_transfer_v1',
            ]);

            $update = [];
            self::setIfColumn($update, 'orders', 'stripe_payment_intent_id', $paymentIntentId);
            self::setIfColumn($update, 'orders', 'stripe_charge_id', $chargeId);
            self::setIfColumn($update, 'orders', 'stripe_transfer_id', $transfer->id);
            self::setIfColumn($update, 'orders', 'stripe_currency', 'brl');

            if (Schema::hasColumn('orders', 'stripe_application_fee_amount')) {
                $platformRetained = ((float)($order->order_amount ?? 0)) - ((float)($tx->store_amount ?? 0));
                $update['stripe_application_fee_amount'] = number_format($platformRetained, 2, '.', '');
            }

            if (!empty($update)) {
                $update['updated_at'] = now();
                DB::table('orders')->where('id', $orderId)->update($update);
            }

            info('FoxGoStripeConnect: auto split OK order_id=' . $orderId . ' transfer_id=' . $transfer->id . ' amount_cents=' . $storeAmountCents);

            return [
                'ok' => true,
                'reason' => 'transfer_created',
                'order_id' => $orderId,
                'stripe_transfer_id' => $transfer->id,
                'amount_cents' => $storeAmountCents,
                'destination' => $vendor->stripe_account_id,
            ];

        } catch (Throwable $e) {
            info('FoxGoStripeConnect: erro auto split order_id=' . $orderId . ' erro=' . $e->getMessage());

            return [
                'ok' => false,
                'reason' => 'exception',
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ];
        }
    }

    private static function skip(string $reason, int $orderId, array $extra = []): array
    {
        $data = array_merge([
            'ok' => false,
            'reason' => $reason,
            'order_id' => $orderId,
        ], $extra);

        info('FoxGoStripeConnect: skip ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));

        return $data;
    }

    private static function moneyToCents($value): int
    {
        return (int) round(((float)$value) * 100);
    }

    private static function setIfColumn(array &$data, string $table, string $column, $value): void
    {
        if (Schema::hasColumn($table, $column) && $value !== null) {
            $data[$column] = $value;
        }
    }

    private static function stripeApiKey(): ?string
    {
        $row = DB::table('addon_settings')->where('key_name', 'stripe')->first();

        if (!$row) {
            return null;
        }

        $mode = $row->mode ?: 'test';
        $values = json_decode($mode === 'live' ? ($row->live_values ?: '{}') : ($row->test_values ?: '{}'), true);

        if (!is_array($values) || empty($values['api_key'])) {
            $values = json_decode($row->test_values ?: '{}', true);
        }

        return is_array($values) ? ($values['api_key'] ?? null) : null;
    }

    private static function paymentIntentId($order, int $orderId): ?string
    {
        if (Schema::hasColumn('orders', 'stripe_payment_intent_id') && !empty($order->stripe_payment_intent_id)) {
            return $order->stripe_payment_intent_id;
        }

        if (!Schema::hasTable('payment_requests')) {
            return null;
        }

        $paymentRequest = null;

        if (Schema::hasColumn('payment_requests', 'attribute_id')) {
            $paymentRequest = DB::table('payment_requests')
                ->where('attribute_id', $orderId)
                ->orderByDesc('created_at')
                ->first();
        }

        if ($paymentRequest && !empty($paymentRequest->transaction_id) && str_starts_with((string)$paymentRequest->transaction_id, 'pi_')) {
            return $paymentRequest->transaction_id;
        }

        return null;
    }
}
