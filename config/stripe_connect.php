<?php

return [
    'enabled' => env('STRIPE_CONNECT_ENABLED', false),
    'mode' => env('STRIPE_CONNECT_MODE', 'test'),

    'secret' => env('STRIPE_CONNECT_SECRET'),
    'publishable_key' => env('STRIPE_CONNECT_PUBLISHABLE_KEY'),
    'webhook_secret' => env('STRIPE_CONNECT_WEBHOOK_SECRET'),

    'default_platform_fee_percent' => env('STRIPE_CONNECT_DEFAULT_PLATFORM_FEE_PERCENT', 0),

    'enable_vendor_onboarding' => env('STRIPE_CONNECT_ENABLE_VENDOR_ONBOARDING', false),
    'enable_deliveryman_onboarding' => env('STRIPE_CONNECT_ENABLE_DELIVERYMAN_ONBOARDING', false),
];
