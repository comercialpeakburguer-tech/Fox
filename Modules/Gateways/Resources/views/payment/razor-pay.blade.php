@extends('Gateways::payment.layouts.master')

@push('script')
    <link rel="stylesheet" href="{{asset('Modules/Gateways/public/assets/modules/css/razor-pay.css')}}">
    <link rel="stylesheet" href="{{asset('Modules/Gateways/public/assets/modules/css/common.css')}}">
@endpush

@section('content')
    <h1 class="text-center">{{translate('Please do not refresh this page')}}...</h1>

    <form action="{!!route('razor-pay.payment',['payment_id'=>$data->id])!!}" id="form" method="POST">
        @csrf
        <script src="https://checkout.razorpay.com/v1/checkout.js"
                data-key="{{ config()->get('razor_config.api_key') }}"
                data-amount="{{round($data->payment_amount, 2)*100}}"
                data-buttontext="Pay {{ round($data->payment_amount, 2) . ' ' . $data->currency_code }}"
                data-name="{{ $business_name ?? '' }}"
                data-description="{{$data->payment_amount}}"
                data-image="{{ $business_logo ?? '' }}"
                data-prefill.name="{{$payer->name ?? ''}}"
                data-prefill.email="{{$payer->email ?? ''}}"
                data-prefill.contact="{{ $payer->phone ?? '' }}"
                data-callback_url="{{ route('razor-pay.callback',['payment_data'=> base64_encode($data->id)]) }}"
                data-theme.color="#ff7529">
        </script>
        <button class="btn btn-block d--none" id="pay-button" type="submit"></button>
        <button class="razorpay-cancel-button" type="button" id="cancel-button" onclick="handleCancel()">Cancel</button>
    </form>

    @push('script_2')
        <script src="{{asset('Modules/Gateways/public/assets/modules/js/razor-pay.js')}}"></script>

        <script type="text/javascript">
            "use strict";
            function handleCancel() {
                window.location.href = '{{ route('razor-pay.cancel', ['payment_id' => $data->id]) }}';
            }
        </script>
    @endpush
@endsection
