<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'foxgo_bag_count')) {
                $table->unsignedInteger('foxgo_bag_count')->nullable()->after('dm_vehicle_id');
            }

            if (!Schema::hasColumn('orders', 'foxgo_volume_count')) {
                $table->unsignedInteger('foxgo_volume_count')->nullable()->after('foxgo_bag_count');
            }

            if (!Schema::hasColumn('orders', 'foxgo_logistics_weight_kg')) {
                $table->decimal('foxgo_logistics_weight_kg', 10, 3)->nullable()->after('foxgo_volume_count');
            }

            if (!Schema::hasColumn('orders', 'foxgo_logistics_payload')) {
                $table->json('foxgo_logistics_payload')->nullable()->after('foxgo_logistics_weight_kg');
            }

            if (!Schema::hasColumn('orders', 'foxgo_pickup_otp_verified_at')) {
                $table->timestamp('foxgo_pickup_otp_verified_at')->nullable()->after('foxgo_logistics_payload');
            }

            if (!Schema::hasColumn('orders', 'foxgo_pickup_otp_verified_by')) {
                $table->unsignedBigInteger('foxgo_pickup_otp_verified_by')->nullable()->after('foxgo_pickup_otp_verified_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            foreach ([
                'foxgo_pickup_otp_verified_by',
                'foxgo_pickup_otp_verified_at',
                'foxgo_logistics_payload',
                'foxgo_logistics_weight_kg',
                'foxgo_volume_count',
                'foxgo_bag_count',
            ] as $column) {
                if (Schema::hasColumn('orders', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
