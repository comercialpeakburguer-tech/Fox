<?php

use Illuminate\Support\Facades\Route;

Route::group(['namespace' => 'Admin', 'as' => 'admin.', 'middleware' => ['admin', 'actch:admin_panel']], function () {
    Route::post('foxgo-v39/store/{store}/verification-status', 'FoxGoV39Controller@storeVerificationStatus')
        ->name('foxgo-v39.store.verification-status');
});
