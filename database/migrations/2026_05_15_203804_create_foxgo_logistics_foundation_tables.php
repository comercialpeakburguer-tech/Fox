<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('foxgo_delivery_vehicle_rules')) {
            Schema::create('foxgo_delivery_vehicle_rules', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('vehicle_id')->index();
                $table->string('vehicle_type')->nullable()->index();
                $table->string('vehicle_name')->nullable();
                $table->decimal('max_distance_km', 8, 2)->nullable();
                $table->decimal('max_weight_kg', 8, 3)->nullable();
                $table->string('max_volume_label')->nullable();
                $table->json('allowed_module_ids')->nullable();
                $table->json('blocked_module_ids')->nullable();
                $table->boolean('is_delivery')->default(true);
                $table->boolean('is_enabled')->default(false);
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->unique(['vehicle_id'], 'foxgo_vehicle_rule_vehicle_unique');
            });
        }

        if (!Schema::hasTable('foxgo_delivery_pricing_rules')) {
            Schema::create('foxgo_delivery_pricing_rules', function (Blueprint $table) {
                $table->id();
                $table->string('rule_code')->unique();
                $table->string('rule_name');
                $table->unsignedBigInteger('module_id')->nullable()->index();
                $table->unsignedBigInteger('parcel_category_id')->nullable()->index();
                $table->unsignedBigInteger('vehicle_id')->nullable()->index();
                $table->decimal('min_distance_km', 8, 2)->default(0);
                $table->decimal('max_distance_km', 8, 2)->nullable();
                $table->decimal('customer_base_fee', 10, 2)->default(0);
                $table->decimal('customer_per_km_fee', 10, 2)->default(0);
                $table->decimal('driver_base_payout', 10, 2)->default(0);
                $table->decimal('driver_per_km_payout', 10, 2)->default(0);
                $table->decimal('minimum_order_amount', 10, 2)->nullable();
                $table->boolean('is_enabled')->default(false);
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->index(['module_id', 'vehicle_id'], 'foxgo_price_module_vehicle_idx');
            });
        }

        if (!Schema::hasTable('foxgo_delivery_dispatch_rules')) {
            Schema::create('foxgo_delivery_dispatch_rules', function (Blueprint $table) {
                $table->id();
                $table->string('rule_code')->unique();
                $table->string('rule_name');
                $table->unsignedBigInteger('module_id')->nullable()->index();
                $table->unsignedBigInteger('parcel_category_id')->nullable()->index();
                $table->string('volume_label')->nullable()->index();
                $table->decimal('max_weight_kg', 8, 3)->nullable();
                $table->decimal('max_distance_km', 8, 2)->nullable();
                $table->unsignedBigInteger('primary_vehicle_id')->index();
                $table->unsignedBigInteger('fallback_vehicle_id')->nullable()->index();
                $table->integer('priority_order')->default(100);
                $table->boolean('bike_allowed')->default(false);
                $table->boolean('market_block_bike')->default(false);
                $table->boolean('requires_manual_review')->default(false);
                $table->boolean('is_enabled')->default(false);
                $table->text('notes')->nullable();
                $table->timestamps();

                $table->index(['module_id', 'priority_order'], 'foxgo_dispatch_module_priority_idx');
            });
        }

        if (!Schema::hasTable('foxgo_item_logistics_profiles')) {
            Schema::create('foxgo_item_logistics_profiles', function (Blueprint $table) {
                $table->id();
                $table->string('profile_scope')->default('item')->index();
                $table->unsignedBigInteger('item_id')->nullable()->index();
                $table->unsignedBigInteger('category_id')->nullable()->index();
                $table->unsignedBigInteger('module_id')->nullable()->index();
                $table->decimal('weight_kg', 8, 3)->nullable();
                $table->string('volume_label')->nullable()->index();
                $table->decimal('length_cm', 8, 2)->nullable();
                $table->decimal('width_cm', 8, 2)->nullable();
                $table->decimal('height_cm', 8, 2)->nullable();
                $table->boolean('bike_allowed')->default(false);
                $table->boolean('motorcycle_allowed')->default(true);
                $table->boolean('car_required')->default(false);
                $table->boolean('utility_required')->default(false);
                $table->boolean('van_required')->default(false);
                $table->boolean('manual_review_required')->default(false);
                $table->boolean('is_enabled')->default(true);
                $table->timestamps();

                $table->unique(['profile_scope', 'item_id'], 'foxgo_logistics_profile_item_unique');
                $table->index(['module_id', 'volume_label'], 'foxgo_logistics_module_volume_idx');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_item_logistics_profiles');
        Schema::dropIfExists('foxgo_delivery_dispatch_rules');
        Schema::dropIfExists('foxgo_delivery_pricing_rules');
        Schema::dropIfExists('foxgo_delivery_vehicle_rules');
    }
};
