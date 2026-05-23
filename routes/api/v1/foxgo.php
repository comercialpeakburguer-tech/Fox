<?php

use Illuminate\Support\Facades\Route;

Route::group(['namespace' => 'Api\\V1', 'middleware' => 'localization'], function () {
    Route::get('app-download-section', 'FoxGoConfigController@appDownloadSection');

    Route::group(['prefix' => 'reels'], function () {
        Route::get('/', 'FoxGoReelController@index');
    });

    Route::group(['prefix' => 'delivery-man', 'middleware' => 'actch:deliveryman_app'], function () {
        Route::group(['middleware' => ['dm.api']], function () {
            Route::get('available-requests', 'DeliverymanController@available_requests');
            Route::put('release-to-another-deliveryman', 'DeliverymanController@foxgo_release_to_another_deliveryman');
            Route::get('new-earning-report', 'DeliverymanEarningReportController@getEarningReport');
        });
    });

    Route::group(['prefix' => 'vendor', 'namespace' => 'Vendor', 'middleware' => ['vendor.api', 'actch:vendor_app']], function () {
        Route::get('earning-report', 'StoreEarningReportController@getEarningReport');
    });

    Route::group(['prefix' => 'vendor', 'middleware' => ['vendor.api', 'actch:vendor_app']], function () {
        Route::get('reels', 'FoxGoReelController@vendorList');
        Route::post('reels/store', 'FoxGoReelController@vendorStore');
        Route::put('reels/status', 'FoxGoReelController@vendorStatus');
    });

    Route::group(['prefix' => 'customer', 'middleware' => ['auth:api']], function () {
        Route::get('saved-files', 'FoxGoSavedPrescriptionController@index');
        Route::post('saved-files/store', 'FoxGoSavedPrescriptionController@store');
        Route::delete('saved-files/delete-all', 'FoxGoSavedPrescriptionController@deleteAll');
    });
});
