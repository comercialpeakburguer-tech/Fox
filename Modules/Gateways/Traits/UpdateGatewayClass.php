<?php

namespace Modules\Gateways\Traits;

use Modules\Gateways\Entities\Setting;

trait UpdateGatewayClass
{
    public function getProcessAllGatewayUpdates(): void
    {
        $this->getInsertDataOfGatewayVersion(version: '1.1');
        $this->getInsertDataOfGatewayVersion(version: '1.2');
        $this->getInsertDataOfGatewayVersion(version: '1.3');
        $this->getInsertDataOfGatewayVersion(version: '1.4');

        $info = include(base_path('Modules/Gateways/Addon/info.php'));
        $info['update_gateway_class'] = 1;
        $str = "<?php return " . var_export($info, true) . ";";
        file_put_contents(base_path('Modules/Gateways/Addon/info.php'), $str);
    }

    public function getInsertDataOfGatewayVersion(string $version): void
    {
        if ($version == '1.1') {
            $this->getAddNewPaymentGateways();
        }

        if ($version == '1.2') {
            $esewaConfig = Setting::where('key_name', 'esewa')->first();
            if ($esewaConfig) {
                $testValues = is_array($esewaConfig->test_values) ? $esewaConfig->test_values : json_decode($esewaConfig->test_values, true);
                $liveValues = is_array($esewaConfig->live_values) ? $esewaConfig->live_values : json_decode($esewaConfig->live_values, true);

                // Update merchant_secret to empty string if null or empty
                $testValues['merchant_secret'] = $testValues['merchant_secret'] ?? '';
                $liveValues['merchant_secret'] = $liveValues['merchant_secret'] ?? '';

                Setting::where('key_name', 'esewa')->update([
                    'test_values' => json_encode($testValues),
                    'live_values' => json_encode($liveValues),
                ]);
            }

            $pvitConfig = Setting::where('key_name', 'pvit')->first();
            if ($pvitConfig) {
                $testValues = is_array($pvitConfig->test_values) ? $pvitConfig->test_values : json_decode($pvitConfig->test_values, true);
                $liveValues = is_array($pvitConfig->live_values) ? $pvitConfig->live_values : json_decode($pvitConfig->live_values, true);

                // Update am_merchant_code to empty string if null or empty
                $testValues['am_merchant_code'] = $testValues['am_merchant_code'] ?? '';
                $liveValues['am_merchant_code'] = $liveValues['am_merchant_code'] ?? '';

                Setting::where('key_name', 'pvit')->update([
                    'test_values' => json_encode($testValues),
                    'live_values' => json_encode($liveValues),
                ]);
            }
        }

        if ($version == '1.3') {
            $payMobAcceptConfig = Setting::where('key_name', 'paymob_accept')->first();
            if ($payMobAcceptConfig && $payMobAcceptConfig->live_values) {

                $liveValues = is_array($payMobAcceptConfig->live_values) ? $payMobAcceptConfig->live_values : json_decode($payMobAcceptConfig->live_values, true);
                $liveValues['supported_country'] = $liveValues['supported_country'] ?? '';
                $liveValues['public_key'] = $liveValues['public_key'] ?? '';
                $liveValues['secret_key'] = $liveValues['secret_key'] ?? '';

                Setting::where('key_name', 'paymob_accept')->update([
                    'live_values' => json_encode($liveValues),
                    'test_values' => json_encode($liveValues),
                ]);
            }

            $momoConfig = Setting::where('key_name', 'momo')->first();
            if ($momoConfig) {
                $liveValues = is_array($momoConfig->live_values) ? $momoConfig->live_values : json_decode($momoConfig->live_values, true);
                $liveValues['target_environment'] = $liveValues['target_environment'] ?? '';

                $testValues = is_array($momoConfig->test_values) ? $momoConfig->test_values : json_decode($momoConfig->test_values, true);
                $testValues['target_environment'] = $testValues['target_environment'] ?? '';

                Setting::where('key_name', 'momo')->update([
                    'live_values' => json_encode($liveValues),
                    'test_values' => json_encode($testValues),
                ]);
            }
        }

        if ($version == '1.4') {
            $mercadoPagoPixConfig = Setting::where('key_name', 'mercadopago_pix')->first();
            if ($mercadoPagoPixConfig) {
                $liveValues = is_array($mercadoPagoPixConfig->live_values) ? $mercadoPagoPixConfig->live_values : json_decode($mercadoPagoPixConfig->live_values, true);
                $testValues = is_array($mercadoPagoPixConfig->test_values) ? $mercadoPagoPixConfig->test_values : json_decode($mercadoPagoPixConfig->test_values, true);
                Setting::where('key_name', 'mercadopago_pix')->update([
                    'live_values' => json_encode($liveValues),
                    'test_values' => json_encode($testValues),
                ]);
            } else {
                Setting::create([
                    'id' => '42a6cad7-6736-11ej-909d-0c7a158e4479',
                    'key_name' => 'mercadopago_pix',
                    'live_values' => json_encode([
                        'gateway' => 'mercadopago_pix',
                        'mode' => 'test',
                        'status' => '0',
                        'token' => '',
                    ]),
                    'test_values' => json_encode([
                        'gateway' => 'mercadopago_pix',
                        'mode' => 'test',
                        'status' => '0',
                        'token' => '',
                    ]),
                    'settings_type' => 'payment_config',
                    'mode' => 'test',
                    'is_active' => 0,
                    'created_at' => null,
                    'updated_at' => null,
                    'additional_data' => null,
                ]);
            }
        }

    }

    public function getAddNewPaymentGateways(): void
    {
        $instamojoConfig = Setting::where('key_name', 'instamojo')->first();
        if ($instamojoConfig) {
            $liveValues = is_array($instamojoConfig->live_values) ? $instamojoConfig->live_values : json_decode($instamojoConfig->live_values, true);
            $testValues = is_array($instamojoConfig->test_values) ? $instamojoConfig->test_values : json_decode($instamojoConfig->test_values, true);
            Setting::where('key_name', 'instamojo')->update([
                'live_values' => json_encode($liveValues),
                'test_values' => json_encode($testValues),
            ]);
        } else {
            Setting::create([
                'id' => '42a8cad7-6736-11ee-909d-0c7a158e4469',
                'key_name' => 'instamojo',
                'live_values' => json_encode([
                    'gateway' => 'instamojo',
                    'mode' => 'test',
                    'status' => '0',
                    'client_id' => '',
                    'client_secret' => ''
                ]),
                'test_values' => json_encode([
                    'gateway' => 'instamojo',
                    'mode' => 'test',
                    'status' => '0',
                    'client_id' => '',
                    'client_secret' => ''
                ]),
                'settings_type' => 'payment_config',
                'mode' => 'test',
                'is_active' => 0,
                'created_at' => null,
                'updated_at' => null,
                'additional_data' => null,
            ]);
        }

        $phonePeConfig = Setting::where('key_name', 'phonepe')->first();
        if ($phonePeConfig) {
            $liveValues = is_array($phonePeConfig->live_values) ? $phonePeConfig->live_values : json_decode($phonePeConfig->live_values, true);
            $testValues = is_array($phonePeConfig->test_values) ? $phonePeConfig->test_values : json_decode($phonePeConfig->test_values, true);
            Setting::where('key_name', 'phonepe')->update([
                'live_values' => json_encode($liveValues),
                'test_values' => json_encode($testValues),
            ]);
        } else {
            Setting::create([
                'id' => 'a40991e4-6735-11ee-909d-0c7a158e4469',
                'key_name' => 'phonepe',
                'live_values' => json_encode([
                    'gateway' => 'phonepe',
                    'mode' => 'test',
                    'status' => 0,
                    'merchant_id' => '',
                    'salt_Key' => '',
                    'salt_index' => ''
                ]),
                'test_values' => json_encode([
                    'gateway' => 'phonepe',
                    'mode' => 'test',
                    'status' => 0,
                    'merchant_id' => '',
                    'salt_Key' => '',
                    'salt_index' => ''
                ]),
                'settings_type' => 'payment_config',
                'mode' => 'test',
                'is_active' => 0,
                'created_at' => null,
                'updated_at' => null,
                'additional_data' => null,
            ]);
        }

        $cashFreeConfig = Setting::where('key_name', 'cashfree')->first();
        if ($cashFreeConfig) {
            $liveValues = is_array($cashFreeConfig->live_values) ? $cashFreeConfig->live_values : json_decode($cashFreeConfig->live_values, true);
            $testValues = is_array($cashFreeConfig->test_values) ? $cashFreeConfig->test_values : json_decode($cashFreeConfig->test_values, true);
            Setting::where('key_name', 'cashfree')->update([
                'live_values' => json_encode($liveValues),
                'test_values' => json_encode($testValues),
            ]);
        } else {
            Setting::create([
                'id' => 'cc90e5f2-6735-11ee-909d-0c7a158e4469',
                'key_name' => 'cashfree',
                'live_values' => json_encode([
                    'gateway' => 'cashfree',
                    'mode' => 'test',
                    'status' => 0,
                    'client_id' => '',
                    'client_secret' => ''
                ]),
                'test_values' => json_encode([
                    'gateway' => 'cashfree',
                    'mode' => 'test',
                    'status' => 0,
                    'client_id' => '',
                    'client_secret' => ''
                ]),
                'settings_type' => 'payment_config',
                'mode' => 'test',
                'is_active' => 0,
                'created_at' => null,
                'updated_at' => null,
                'additional_data' => null,
            ]);
        }
    }
}
