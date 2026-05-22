<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('foxgo_pagarme_recipients')) {
            return;
        }

        Schema::create('foxgo_pagarme_recipients', function (Blueprint $table) {
            $table->id();

            $table->string('owner_type', 40)->comment('store|deliveryman');
            $table->unsignedBigInteger('owner_id');

            $table->unsignedBigInteger('store_id')->nullable();
            $table->unsignedBigInteger('vendor_id')->nullable();
            $table->unsignedBigInteger('delivery_man_id')->nullable();

            $table->string('environment', 20)->default('live');
            $table->string('recipient_id', 120)->nullable();
            $table->string('status', 40)->default('pending');

            $table->string('legal_name')->nullable();
            $table->string('document_type', 20)->nullable();
            $table->string('document_last4', 8)->nullable();

            $table->string('bank_code', 20)->nullable();
            $table->string('bank_account_last4', 12)->nullable();

            $table->boolean('transfer_enabled')->default(false);
            $table->boolean('split_enabled')->default(false);

            $table->timestamp('last_sync_at')->nullable();
            $table->json('metadata')->nullable();
            $table->text('error_message')->nullable();

            $table->timestamps();

            $table->unique(['owner_type', 'owner_id', 'environment'], 'foxgo_pagarme_owner_env_unique');
            $table->unique(['recipient_id', 'environment'], 'foxgo_pagarme_recipient_env_unique');
            $table->index(['store_id', 'environment'], 'foxgo_pagarme_store_env_index');
            $table->index(['vendor_id', 'environment'], 'foxgo_pagarme_vendor_env_index');
            $table->index(['delivery_man_id', 'environment'], 'foxgo_pagarme_dm_env_index');
            $table->index(['status', 'environment'], 'foxgo_pagarme_status_env_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_pagarme_recipients');
    }
};