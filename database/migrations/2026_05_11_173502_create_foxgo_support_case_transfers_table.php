<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('foxgo_support_case_transfers')) {
            Schema::create('foxgo_support_case_transfers', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('case_id')->index();
                $table->unsignedBigInteger('from_department_id')->nullable()->index();
                $table->unsignedBigInteger('to_department_id')->nullable()->index();
                $table->unsignedBigInteger('from_admin_id')->nullable()->index();
                $table->unsignedBigInteger('to_admin_id')->nullable()->index();
                $table->string('reason')->nullable();
                $table->longText('internal_note')->nullable();
                $table->string('status_before')->nullable();
                $table->string('status_after')->nullable();
                $table->timestamps();

                $table->index(['case_id', 'to_department_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_support_case_transfers');
    }
};
