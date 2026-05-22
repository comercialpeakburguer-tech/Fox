<?php

namespace Modules\Gateways\Http\Controllers;


use App\Models\User;
use Illuminate\Foundation\Application;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Routing\Redirector;
use Illuminate\Support\Facades\Validator;
use Modules\Gateways\Entities\PaymentRequest;
use Modules\Gateways\Traits\Processor;
use Ramsey\Uuid\Uuid;

class MercadoPagoPixController extends Controller
{
use Processor;

private PaymentRequest $paymentRequest;
private mixed $config;
private User $user;

public function __construct(PaymentRequest $paymentRequest, User $user)
{
    $config = $this->payment_config('mercadopago_pix', 'payment_config');
    if (!is_null($config) && $config->mode == 'live') {
        $this->config = json_decode($config->live_values, true);
    } elseif (!is_null($config) && $config->mode == 'test') {
        $this->config = json_decode($config->test_values, true);
    }
    $this->paymentRequest = $paymentRequest;
    $this->user = $user;
}


public function payment(Request $request)
{
    $validator = Validator::make($request->all(), [
        'payment_id' => 'required|uuid'
    ]);

    if ($validator->fails()) {
        return response()->json($this->response_formatter(GATEWAYS_DEFAULT_400, null, $this->error_processor($validator)), 400);
    }

    $payment_data = $this->paymentRequest::where(['id' => $request['payment_id']])->where(['is_paid' => 0])->first();
    if (!isset($payment_data)) {
        return response()->json($this->response_formatter(GATEWAYS_DEFAULT_204), 200);
    }
    $payer = json_decode($payment_data['payer_information']);
    $config = $this->config;
    $data = array(
        "binary_mode" => true,
        "callback_url" => route('mercadopago_pix.callback'),
        "notification_url" => route('mercadopago_pix.notification'),
        "description" => "Payment for product",
        "external_reference" => $request['payment_id'],
        "installments" => 1,
        "metadata" => array(),
        "payer" => array(
            "entity_type" => "individual",
            "type" => "customer",
            "email" => $payer->email ?? "rnrashedrn@gmail.com",
            "identification" => array(
                "type" => "CPF",
                "number" => "95749019047"
            )
        ),
        "payment_method_id" => "pix",
        "transaction_amount" => round($payment_data->payment_amount),
    );

    $json_data = json_encode($data);

    $ch = curl_init('https://api.mercadopago.com/v1/payments');
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $json_data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        'Authorization: Bearer ' . $config['access_token'],
        'Content-Type: application/json',
        'X-Idempotency-Key: ' . Uuid::uuid4()->toString()
    ));

    $response = curl_exec($ch);
    curl_close($ch);
    $result = json_decode($response, true);
    if (isset($result['point_of_interaction'])) {
        return redirect()->to($result['point_of_interaction']['transaction_data']['ticket_url']);
    }
    if (isset($payment_data) && function_exists($payment_data->failure_hook)) {
        call_user_func($payment_data->failure_hook, $payment_data);
    }
    return $this->payment_response($payment_data, 'fail');
}

public function callback(Request $request)
{
    $config = $this->config;
    //$access_token = 'APP_USR-7637178661205443-092717-7471e6ab4f5cd60b1e1176a6e03d61ae-246996053';
    if ($request->action && $request->action == 'payment.updated') {
        $payment_id = $request->data_id;
        $api_url = "https://api.mercadopago.com/v1/payments/$payment_id";

        $headers = [
            'Authorization: Bearer ' . $config['access_token'],
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $api_url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

        $response = curl_exec($ch);
        curl_close($ch);
        $result = json_decode($response, true);
        if (isset($result['status']) && $result['status'] == 'approved') {
            $data = $this->paymentRequest::where(['id' => $result['external_reference']])->where(['is_paid' => 0])->first();
            if (isset($data) && function_exists($data->success_hook)) {
                call_user_func($data->success_hook, $data);
            }
        }
    }
}
public function notification(Request $request)
{
    info('notification');
    info($request->data_id);
     info($request->id);
    $config = $this->config;
    //$access_token = 'APP_USR-7637178661205443-092717-7471e6ab4f5cd60b1e1176a6e03d61ae-246996053';
    if ($request->action && $request->action == 'payment.updated') {
        info('done');
        $payment_id = $request->data_id;
        $api_url = "https://api.mercadopago.com/v1/payments/$payment_id";

        $headers = [
            'Authorization: Bearer ' . $config['access_token'],
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $api_url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

        $response = curl_exec($ch);
        curl_close($ch);
        $result = json_decode($response, true);
        info($result);
        if (isset($result['status']) && $result['status'] == 'approved') {
            $data = $this->paymentRequest::where(['id' => $result['external_reference']])->where(['is_paid' => 0])->first();
            if (isset($data) && function_exists($data->success_hook)) {
                call_user_func($data->success_hook, $data);
            }
        }
    }
}
}
