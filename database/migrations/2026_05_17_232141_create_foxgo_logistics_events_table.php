<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('foxgo_logistics_events')) {
            return;
        }

        Schema::create('foxgo_logistics_events', function (Blueprint $table) {
            $table->id();
            $table->uuid('event_uuid')->unique();

            $table->string('event_type', 80)->index();
            $table->string('mission_type', 50)->nullable()->index();

            $table->string('subject_type', 50)->nullable()->index();
            $table->unsignedBigInteger('subject_id')->nullable()->index();

            $table->unsignedBigInteger('order_id')->nullable()->index();
            $table->unsignedBigInteger('store_id')->nullable()->index();
            $table->unsignedBigInteger('user_id')->nullable()->index();
            $table->unsignedBigInteger('delivery_man_id')->nullable()->index();

            $table->string('actor_type', 50)->nullable()->index();
            $table->unsignedBigInteger('actor_id')->nullable()->index();

            $table->string('source', 80)->nullable()->index();
            $table->string('status_from', 60)->nullable();
            $table->string('status_to', 60)->nullable();

            $table->string('queue_name', 80)->nullable()->index();
            $table->string('correlation_id', 120)->nullable()->index();

            $table->timestamp('occurred_at')->nullable()->index();

            $table->json('payload')->nullable();
            $table->json('metadata')->nullable();

            $table->timestamps();

            $table->index(['event_type', 'occurred_at']);
            $table->index(['order_id', 'event_type']);
            $table->index(['delivery_man_id', 'event_type']);
            $table->index(['mission_type', 'event_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_logistics_events');
    }
};
