<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'foxgo_pickup_otp')) {
                $table->string('foxgo_pickup_otp', 4)->nullable()->after('foxgo_pickup_otp_verified_by');
            }

            if (!Schema::hasColumn('orders', 'foxgo_pickup_otp_generated_at')) {
                $table->timestamp('foxgo_pickup_otp_generated_at')->nullable()->after('foxgo_pickup_otp');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'foxgo_pickup_otp_generated_at')) {
                $table->dropColumn('foxgo_pickup_otp_generated_at');
            }

            if (Schema::hasColumn('orders', 'foxgo_pickup_otp')) {
                $table->dropColumn('foxgo_pickup_otp');
            }
        });
    }
};
