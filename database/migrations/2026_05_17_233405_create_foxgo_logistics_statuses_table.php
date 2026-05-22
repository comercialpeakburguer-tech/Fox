<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('foxgo_logistics_statuses')) {
            return;
        }

        Schema::create('foxgo_logistics_statuses', function (Blueprint $table) {
            $table->id();
            $table->uuid('status_uuid')->unique();

            $table->string('mission_type', 50)->nullable();
            $table->string('subject_type', 50)->nullable();
            $table->unsignedBigInteger('subject_id')->nullable();

            $table->unsignedBigInteger('order_id')->nullable();
            $table->unsignedBigInteger('store_id')->nullable();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->unsignedBigInteger('delivery_man_id')->nullable();

            $table->unsignedBigInteger('current_offer_id')->nullable();
            $table->unsignedBigInteger('current_batch_id')->nullable();
            $table->unsignedBigInteger('last_event_id')->nullable();

            $table->string('operational_status', 60)->default('created');
            $table->string('payment_status', 60)->nullable();
            $table->string('dispatch_status', 60)->nullable();
            $table->string('pickup_status', 60)->nullable();
            $table->string('dropoff_status', 60)->nullable();
            $table->string('support_status', 60)->nullable();
            $table->string('risk_level', 30)->default('normal');

            $table->decimal('driver_earning_amount', 12, 2)->nullable();
            $table->decimal('distance_to_pickup_km', 10, 3)->nullable();
            $table->decimal('total_distance_km', 10, 3)->nullable();
            $table->integer('eta_to_pickup_seconds')->nullable();
            $table->integer('eta_total_seconds')->nullable();

            $table->timestamp('last_event_at')->nullable();
            $table->timestamp('status_updated_at')->nullable();

            $table->string('source', 80)->nullable();
            $table->string('correlation_id', 120)->nullable();

            $table->json('payload')->nullable();
            $table->json('metadata')->nullable();

            $table->timestamps();

            $table->index(['order_id'], 'fg_ls_order_idx');
            $table->index(['delivery_man_id'], 'fg_ls_dm_idx');
            $table->index(['current_offer_id'], 'fg_ls_offer_idx');
            $table->index(['mission_type', 'operational_status'], 'fg_ls_mission_status_idx');
            $table->index(['dispatch_status', 'risk_level'], 'fg_ls_dispatch_risk_idx');
            $table->index(['status_updated_at'], 'fg_ls_updated_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_logistics_statuses');
    }
};
