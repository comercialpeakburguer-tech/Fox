<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('foxgo_reels')) {
            Schema::create('foxgo_reels', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('store_id')->index();
                $table->unsignedBigInteger('item_id')->nullable()->index();
                $table->unsignedBigInteger('zone_id')->nullable()->index();
                $table->unsignedBigInteger('module_id')->nullable()->index();
                $table->string('title')->nullable();
                $table->text('description')->nullable();
                $table->string('thumbnail')->nullable();
                $table->string('thumbnail_storage')->default('public');
                $table->string('video')->nullable();
                $table->string('video_storage')->default('public');
                $table->text('video_link')->nullable();
                $table->tinyInteger('status')->default(1)->index();
                $table->integer('sort_order')->default(0);
                $table->timestamp('starts_at')->nullable();
                $table->timestamp('ends_at')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_reels');
    }
};
