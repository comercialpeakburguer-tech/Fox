<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\BusinessSetting;
use App\Models\DataSetting;

class FoxGoConfigController extends Controller
{
    public function appDownloadSection()
    {
        $datas = DataSetting::with('translations')
            ->where('type', 'app_settings')
            ->whereIn('key', ['download_user_app_section_status', 'download_user_app_title'])
            ->get();

        $settings = [];

        foreach ($datas as $value) {
            if (count($value->translations) > 0) {
                $settings[$value->key] = $value->translations[0]['value'];
            } else {
                $settings[$value->key] = $value->value;
            }
        }

        return response()->json([
            'download_user_app_section_status' => (int)($settings['download_user_app_section_status'] ?? 0),
            'download_user_app_title' => $settings['download_user_app_title'] ?? null,
            'download_user_app_links' => [
                'playstore_url' => BusinessSetting::where('key', 'app_url_android')->value('value'),
                'apple_store_url' => BusinessSetting::where('key', 'app_url_ios')->value('value'),
            ],
        ]);
    }
}
