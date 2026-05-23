<?php

namespace App\Services\FoxGo;

class DispatchScoringService
{
    public static function calculateCandidate(array $candidate): array
    {
        $active = (bool) ($candidate['active'] ?? false);
        $online = (bool) ($candidate['online'] ?? false);
        $approved = (bool) ($candidate['approved'] ?? false);
        $hasPushToken = (bool) ($candidate['has_push_token'] ?? false);

        $distanceToPickupKm = (float) ($candidate['distance_to_pickup_km'] ?? 999);
        $totalDistanceKm = (float) ($candidate['total_distance_km'] ?? 0);
        $etaToPickupSeconds = (int) ($candidate['eta_to_pickup_seconds'] ?? 0);
        $currentOrders = (int) ($candidate['current_orders'] ?? 0);
        $maxOrders = max(1, (int) ($candidate['max_orders'] ?? 2));
        $recentRejects = (int) ($candidate['recent_rejects'] ?? 0);
        $lateRiskPercent = (float) ($candidate['late_risk_percent'] ?? 0);
        $routeCompatibility = (float) ($candidate['route_compatibility'] ?? 0);
        $priorityBonus = (float) ($candidate['priority_bonus'] ?? 0);

        $disqualified = false;
        $reasons = [];

        if (!$active) {
            $disqualified = true;
            $reasons[] = 'deliveryman_inactive';
        }
        if (!$online) {
            $disqualified = true;
            $reasons[] = 'deliveryman_offline';
        }
        if (!$approved) {
            $disqualified = true;
            $reasons[] = 'deliveryman_not_approved';
        }
        if (!$hasPushToken) {
            $disqualified = true;
            $reasons[] = 'missing_push_token';
        }
        if ($currentOrders >= $maxOrders) {
            $disqualified = true;
            $reasons[] = 'max_orders_reached';
        }

        $score = ($distanceToPickupKm * 100)
            + (($etaToPickupSeconds / 60) * 12)
            + ($currentOrders * 250)
            + ($recentRejects * 180)
            + ($lateRiskPercent * 4)
            + ($totalDistanceKm * 8)
            - ($routeCompatibility * 120)
            - $priorityBonus;

        if ($disqualified) {
            $score += 100000;
        }

        return [
            'score' => round($score, 4),
            'disqualified' => $disqualified,
            'reasons' => $reasons,
            'distance_to_pickup_km' => round($distanceToPickupKm, 3),
            'total_distance_km' => round($totalDistanceKm, 3),
            'eta_to_pickup_seconds' => $etaToPickupSeconds,
            'current_orders' => $currentOrders,
            'max_orders' => $maxOrders,
            'recent_rejects' => $recentRejects,
            'late_risk_percent' => round($lateRiskPercent, 2),
            'route_compatibility' => round($routeCompatibility, 4),
        ];
    }

    public static function estimateDriverEarning(array $mission): array
    {
        $baseAmount = (float) ($mission['base_amount'] ?? 4.00);
        $perKmAmount = (float) ($mission['per_km_amount'] ?? 1.20);
        $minimumAmount = (float) ($mission['minimum_amount'] ?? 6.00);
        $distanceKm = (float) ($mission['total_distance_km'] ?? 0);
        $extraAmount = (float) ($mission['extra_amount'] ?? 0);
        $priorityAmount = (float) ($mission['priority_amount'] ?? 0);

        $amount = $baseAmount + ($distanceKm * $perKmAmount) + $extraAmount + $priorityAmount;
        $amount = max($minimumAmount, $amount);

        return [
            'driver_earning_amount' => round($amount, 2),
            'base_amount' => round($baseAmount, 2),
            'per_km_amount' => round($perKmAmount, 2),
            'minimum_amount' => round($minimumAmount, 2),
            'total_distance_km' => round($distanceKm, 3),
            'extra_amount' => round($extraAmount, 2),
            'priority_amount' => round($priorityAmount, 2),
            'label' => 'Voce recebe',
        ];
    }
}
