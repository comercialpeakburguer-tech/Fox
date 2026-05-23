<?php

use Illuminate\Support\Facades\Route;

Route::group(['namespace' => 'Api\\V1', 'middleware' => 'localization'], function () {
    Route::group(['prefix' => 'delivery-man', 'middleware' => 'actch:deliveryman_app'], function () {
        Route::group(['middleware' => ['dm.api']], function () {
            Route::get('available-requests', 'DeliverymanController@available_requests');
            Route::put('release-to-another-deliveryman', 'DeliverymanController@foxgo_release_to_another_deliveryman');
        });
    });
});
