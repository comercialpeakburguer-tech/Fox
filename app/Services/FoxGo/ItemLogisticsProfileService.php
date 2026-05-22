<?php

namespace App\Services\FoxGo;

use App\Models\FoxGoItemLogisticsProfile;

class ItemLogisticsProfileService
{
    private static function nullableFloat($value): ?float
    {
        if ($value === null || $value === '') {
            return null;
        }

        return (float) str_replace(',', '.', (string) $value);
    }

    public static function validationErrors($request, ?string $moduleType): array
    {
        if ($moduleType !== 'grocery') {
            return [];
        }

        $errors = [];

        $weightKg = self::nullableFloat($request->input('foxgo_logistics_weight_kg'));
        $volumeLabel = $request->input('foxgo_volume_label') ?: null;

        if ($weightKg === null || $weightKg <= 0) {
            $errors[] = [
                'code' => 'foxgo_logistics_weight_kg',
                'message' => 'No Mercado, informe o peso do item em kg para a logística Fox GO.'
            ];
        }

        if (!$volumeLabel || !in_array($volumeLabel, ['small', 'medium', 'large', 'bulky'], true)) {
            $errors[] = [
                'code' => 'foxgo_volume_label',
                'message' => 'No Mercado, selecione o volume do item para a logística Fox GO.'
            ];
        }

        $hasVehicleRule =
            $request->boolean('foxgo_bike_allowed')
            || $request->boolean('foxgo_motorcycle_allowed')
            || $request->boolean('foxgo_car_required')
            || $request->boolean('foxgo_utility_required')
            || $request->boolean('foxgo_van_required');

        if (!$hasVehicleRule) {
            $errors[] = [
                'code' => 'foxgo_vehicle_rule',
                'message' => 'No Mercado, marque pelo menos uma opção logística: Bike, Moto, Carro, Utilitário ou Van.'
            ];
        }

        return $errors;
    }

    public static function saveFromRequest($request, $item): void
    {
        if (!$item || !$item->id) {
            return;
        }

        $item->loadMissing('module');

        $moduleType = $item?->module?->module_type;

        if (!in_array($moduleType, ['grocery', 'pharmacy', 'ecommerce', 'parcel'], true)) {
            return;
        }

        $foxgoFields = [
            'foxgo_logistics_weight_kg',
            'foxgo_volume_label',
            'foxgo_length_cm',
            'foxgo_width_cm',
            'foxgo_height_cm',
            'foxgo_bike_allowed',
            'foxgo_motorcycle_allowed',
            'foxgo_car_required',
            'foxgo_utility_required',
            'foxgo_van_required',
            'foxgo_manual_review_required',
        ];

        $hasFoxgoPayload = false;
        foreach ($foxgoFields as $field) {
            if ($request->has($field)) {
                $hasFoxgoPayload = true;
                break;
            }
        }

        if (!$hasFoxgoPayload) {
            return;
        }

        $weightKg = self::nullableFloat($request->input('foxgo_logistics_weight_kg'));
        $lengthCm = self::nullableFloat($request->input('foxgo_length_cm'));
        $widthCm = self::nullableFloat($request->input('foxgo_width_cm'));
        $heightCm = self::nullableFloat($request->input('foxgo_height_cm'));
        $volumeLabel = $request->input('foxgo_volume_label') ?: null;

        $bikeAllowed = (bool) $request->boolean('foxgo_bike_allowed');
        $motorcycleAllowed = (bool) $request->boolean('foxgo_motorcycle_allowed');
        $carRequired = (bool) $request->boolean('foxgo_car_required');
        $utilityRequired = (bool) $request->boolean('foxgo_utility_required');
        $vanRequired = (bool) $request->boolean('foxgo_van_required');
        $manualReviewRequired = (bool) $request->boolean('foxgo_manual_review_required');

        $existing = FoxGoItemLogisticsProfile::where('item_id', $item->id)->first();

        $hasMeaningfulData =
            $weightKg !== null
            || $lengthCm !== null
            || $widthCm !== null
            || $heightCm !== null
            || $volumeLabel !== null
            || $bikeAllowed
            || $motorcycleAllowed
            || $carRequired
            || $utilityRequired
            || $vanRequired
            || $manualReviewRequired;

        if (!$existing && !$hasMeaningfulData) {
            return;
        }

        FoxGoItemLogisticsProfile::updateOrCreate(
            ['item_id' => $item->id],
            [
                'category_id' => $item->category_id,
                'module_id' => $item->module_id,
                'weight_kg' => $weightKg,
                'volume_label' => $volumeLabel,
                'length_cm' => $lengthCm,
                'width_cm' => $widthCm,
                'height_cm' => $heightCm,
                'bike_allowed' => $bikeAllowed,
                'motorcycle_allowed' => $motorcycleAllowed,
                'car_required' => $carRequired,
                'utility_required' => $utilityRequired,
                'van_required' => $vanRequired,
                'manual_review_required' => $manualReviewRequired,
                'is_enabled' => true,
            ]
        );
    }
}
