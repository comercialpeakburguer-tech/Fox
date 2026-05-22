<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('foxgo_dispatch_offers')) {
            return;
        }

        Schema::create('foxgo_dispatch_offers', function (Blueprint $table) {
            $table->id();
            $table->uuid('offer_uuid')->unique();

            $table->string('mission_type', 50)->nullable()->index();
            $table->string('offer_type', 60)->default('single')->index();

            $table->unsignedBigInteger('order_id')->nullable()->index();
            $table->unsignedBigInteger('store_id')->nullable()->index();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->unsignedBigInteger('delivery_man_id')->nullable()->index();

            $table->string('status', 40)->default('pending')->index();

            $table->decimal('score', 10, 4)->nullable()->index();
            $table->decimal('distance_to_pickup_km', 10, 3)->nullable();
            $table->decimal('total_distance_km', 10, 3)->nullable();
            $table->integer('eta_to_pickup_seconds')->nullable();
            $table->integer('eta_total_seconds')->nullable();

            $table->decimal('driver_earning_amount', 12, 2)->nullable();
            $table->decimal('extra_earning_amount', 12, 2)->nullable();
            $table->decimal('extra_distance_km', 10, 3)->nullable();
            $table->integer('extra_eta_seconds')->nullable();

            $table->unsignedBigInteger('batch_id')->nullable()->index();
            $table->unsignedBigInteger('previous_order_id')->nullable()->index();
            $table->unsignedInteger('sequence')->nullable();

            $table->timestamp('offered_at')->nullable()->index();
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->timestamp('timed_out_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();

            $table->string('rejection_reason', 160)->nullable();
            $table->string('source', 80)->nullable()->index();
            $table->string('correlation_id', 120)->nullable()->index();

            $table->json('payload')->nullable();
            $table->json('metadata')->nullable();

            $table->timestamps();

            $table->index(['order_id', 'status']);
            $table->index(['delivery_man_id', 'status']);
            $table->index(['status', 'expires_at']);
            $table->index(['mission_type', 'offer_type', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_dispatch_offers');
    }
};
