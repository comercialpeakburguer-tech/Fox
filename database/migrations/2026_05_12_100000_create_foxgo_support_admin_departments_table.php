<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('foxgo_support_admin_departments')) {
            Schema::create('foxgo_support_admin_departments', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('admin_id');
                $table->unsignedBigInteger('department_id');
                $table->string('role_in_department')->nullable();
                $table->boolean('can_view_financial_context')->default(false);
                $table->boolean('can_handle_refund')->default(false);
                $table->boolean('can_handle_repasses')->default(false);
                $table->boolean('is_active')->default(true);
                $table->timestamps();

                $table->unique(['admin_id', 'department_id'], 'foxgo_support_admin_department_unique');
                $table->index('admin_id');
                $table->index('department_id');
                $table->index('is_active');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_support_admin_departments');
    }
};
