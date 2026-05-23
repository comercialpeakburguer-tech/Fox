<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('items', function (Blueprint $table) {
            if (!Schema::hasColumn('items', 'video')) {
                $table->string('video')->nullable()->after('image');
            }
            if (!Schema::hasColumn('items', 'video_link')) {
                $table->text('video_link')->nullable()->after('video');
            }
            if (!Schema::hasColumn('items', 'low_stock_alert_quantity')) {
                $table->integer('low_stock_alert_quantity')->nullable()->after('stock');
            }
        });

        Schema::table('stores', function (Blueprint $table) {
            if (!Schema::hasColumn('stores', 'is_verified')) {
                $table->boolean('is_verified')->default(false)->after('status');
            }
            if (!Schema::hasColumn('stores', 'verified_at')) {
                $table->timestamp('verified_at')->nullable()->after('is_verified');
            }
        });
    }

    public function down(): void
    {
        Schema::table('items', function (Blueprint $table) {
            if (Schema::hasColumn('items', 'video')) {
                $table->dropColumn('video');
            }
            if (Schema::hasColumn('items', 'video_link')) {
                $table->dropColumn('video_link');
            }
            if (Schema::hasColumn('items', 'low_stock_alert_quantity')) {
                $table->dropColumn('low_stock_alert_quantity');
            }
        });

        Schema::table('stores', function (Blueprint $table) {
            if (Schema::hasColumn('stores', 'is_verified')) {
                $table->dropColumn('is_verified');
            }
            if (Schema::hasColumn('stores', 'verified_at')) {
                $table->dropColumn('verified_at');
            }
        });
    }
};
