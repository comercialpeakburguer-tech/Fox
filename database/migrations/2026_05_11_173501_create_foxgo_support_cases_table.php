<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('foxgo_support_cases')) {
            Schema::create('foxgo_support_cases', function (Blueprint $table) {
                $table->id();
                $table->string('protocol')->unique();

                $table->unsignedBigInteger('order_id')->nullable()->index();
                $table->unsignedBigInteger('customer_id')->nullable()->index();
                $table->unsignedBigInteger('store_id')->nullable()->index();
                $table->unsignedBigInteger('vendor_id')->nullable()->index();
                $table->unsignedBigInteger('delivery_man_id')->nullable()->index();
                $table->unsignedBigInteger('conversation_id')->nullable()->index();

                $table->string('opened_by_type')->nullable()->index();
                $table->unsignedBigInteger('opened_by_id')->nullable()->index();

                $table->unsignedBigInteger('current_department_id')->nullable()->index();
                $table->unsignedBigInteger('assigned_admin_id')->nullable()->index();

                $table->string('status')->default('aberto')->index();
                $table->string('priority')->default('normal')->index();
                $table->string('reason')->nullable()->index();
                $table->string('subject')->nullable();
                $table->longText('description')->nullable();

                $table->timestamp('sla_due_at')->nullable()->index();
                $table->timestamp('closed_at')->nullable();
                $table->unsignedBigInteger('closed_by')->nullable()->index();

                $table->string('final_decision')->nullable();
                $table->string('loss_responsible_party')->nullable()->index();

                $table->timestamps();

                $table->index(['status', 'current_department_id']);
                $table->index(['order_id', 'status']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_support_cases');
    }
};
