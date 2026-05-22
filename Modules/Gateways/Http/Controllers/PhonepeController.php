<?php

namespace Modules\Gateways\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Routing\Redirector;
use Modules\Gateways\Traits\Processor;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Modules\Gateways\Entities\PaymentRequest;
use Illuminate\Contracts\Foundation\Application;
use PhonePe\Env;
use PhonePe\payments\v1\models\request\builders\InstrumentBuilder;
use PhonePe\payments\v1\models\request\builders\PgPayRequestBuilder;
use PhonePe\payments\v1\PhonePePaymentClient;

class PhonepeController extends Controller
{
    use Processor;

    private mixed $config_values;
    private PaymentRequest $payment;

    public function __construct(PaymentRequest $payment)
    {
        $config = $this->payment_config('phonepe', 'payment_config');
        if (!is_null($config) && $config->mode == 'live') {
            $this->config_values = json_decode($config->live_values);
            $this->config_values->base_url = "https://api.phonepe.com/apis/hermes";
        } elseif (!is_null($config) && $config->mode == 'test') {
            $this->config_values = json_decode($config->test_values);
            $this->config_values->base_url = "https://api-preprod.phonepe.com/apis/pg-sandbox";
        }
        $this->payment = $payment;
    }

    /**
     * @param Request $request
     * @return JsonResponse|RedirectResponse
     */
    public function payment(Request $request)
    {
        //sdk composer require --prefer-source phonepe/phonepe-pg-php-sdk

        $validator = Validator::make($request->all(), [
            'payment_id' => 'required|uuid'
        ]);

        if ($validator->fails()) {
            return response()->json($this->response_formatter(GATEWAYS_DEFAULT_400, null, $this->error_processor($validator)), 400);
        }

        $payment_data = $this->payment::where(['id' => $request['payment_id']])->where(['is_paid' => 0])->first();
        if (!isset($payment_data)) {
            return response()->json($this->response_formatter(GATEWAYS_DEFAULT_204), 200);
        }
        $config = $this->config_values;

        $customer_data = json_decode($payment_data->payer_information, true);

        $merchantTransactionId = substr($payment_data->id, 0, 35);
        $payment_data->transaction_id = $merchantTransactionId;
        $payment_data->save();


        $merchant_id = $config->merchant_id;
        $amount = $payment_data->payment_amount * 100;
        $salt = $config->salt_Key;
        $index = $config->salt_index;
        if ($config->mode == 'live') {
            $env = Env::PRODUCTION;
        } else {
            $env = Env::UAT;
        }
        $SHOULDPUBLISHEVENTS = true;
        $merchantUserId = "tt" . $payment_data->payer_id;

        $phonePePaymentsClient = new PhonePePaymentClient($merchant_id, $salt, $index, $env, $SHOULDPUBLISHEVENTS);
        $request = PgPayRequestBuilder::builder()
            ->mobileNumber($customer_data['phone'])
            ->callbackUrl(route('phonepe.callback', ['transaction_id' => $merchantTransactionId]))
            ->merchantId($merchant_id)
            ->merchantUserId($merchantUserId)
            ->amount($amount)
            ->merchantTransactionId($merchantTransactionId)
            ->redirectUrl(route('phonepe.redirect', ['transaction_id' => $merchantTransactionId]))
            ->redirectMode("REDIRECT")
            ->paymentInstrument(InstrumentBuilder::buildPayPageInstrument())
            ->build();

        $response = $phonePePaymentsClient->pay($request);
        // dd($response);
        $PagPageUrl = $response->getInstrumentResponse()->getRedirectInfo()->getUrl();
        return redirect()->to($PagPageUrl);
    }

    public function callback(Request $request)
    {
        $config = $this->config_values;
        $merchant_id = $config->merchant_id;
        $salt = $config->salt_Key;
        $index = $config->salt_index;
        if ($config->mode == 'live') {
            $env = Env::PRODUCTION;
        } else {
            $env = Env::UAT;
        }
        $SHOULDPUBLISHEVENTS = true;
        $phonePePaymentsClient = new PhonePePaymentClient($merchant_id, $salt, $index, $env, $SHOULDPUBLISHEVENTS);
        $merchantTransactionId = $request['transaction_id'];
        $checkStatus = $phonePePaymentsClient->statusCheck($merchantTransactionId);
        $state = $checkStatus->getState();

        if ($state == "COMPLETED") {

            $this->payment::where(['transaction_id' => $request['transaction_id']])->update([
                'payment_method' => 'phonepe',
                'is_paid' => 1,
                'transaction_id' => $request['transaction_id'],
            ]);

            $data = $this->payment::where(['transaction_id' => $request['transaction_id']])->first();

            // if (isset($data) && function_exists($data->success_hook)) {
            //     call_user_func($data->success_hook, $data);
            // }

            return $this->payment_response($data, 'success');
        }

        $payment_data = $this->payment::where('transaction_id', $request['transaction_id'])->first();
        if (isset($payment_data) && function_exists($payment_data->failure_hook)) {
            call_user_func($payment_data->failure_hook, $payment_data);
        }
        return $this->payment_response($payment_data, 'fail');
    }

    /**
     * @param Request $request
     * @return \Illuminate\Foundation\Application|JsonResponse|Redirector|Application|RedirectResponse
     */
    public function redirect(Request $request)
    {
        $config = $this->config_values;
        $merchant_id = $config->merchant_id;
        $salt = $config->salt_Key;
        $index = $config->salt_index;
        if ($config->mode == 'live') {
            $env = Env::PRODUCTION;
        } else {
            $env = Env::UAT;
        }
        $SHOULDPUBLISHEVENTS = true;
        $phonePePaymentsClient = new PhonePePaymentClient($merchant_id, $salt, $index, $env, $SHOULDPUBLISHEVENTS);
        $merchantTransactionId = $request['transaction_id'];
        $checkStatus = $phonePePaymentsClient->statusCheck($merchantTransactionId);
        $state = $checkStatus->getState();

        if ($state == "COMPLETED") {

            $this->payment::where(['transaction_id' => $request['transaction_id']])->update([
                'payment_method' => 'phonepe',
                'is_paid' => 1,
                'transaction_id' => $request['transaction_id'],
            ]);

            $data = $this->payment::where(['transaction_id' => $request['transaction_id']])->first();

            if (isset($data) && function_exists($data->success_hook)) {
                call_user_func($data->success_hook, $data);
            }

            return $this->payment_response($data, 'success');
        }

        $payment_data = $this->payment::where('transaction_id', $request['transaction_id'])->first();
        if (isset($payment_data) && function_exists($payment_data->failure_hook)) {
            call_user_func($payment_data->failure_hook, $payment_data);
        }
        return $this->payment_response($payment_data, 'fail');
    }
}
