<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->addConnectColumns('vendors');
        $this->addConnectColumns('delivery_men');

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'stripe_payment_intent_id')) {
                $table->string('stripe_payment_intent_id', 255)->nullable();
            }

            if (!Schema::hasColumn('orders', 'stripe_charge_id')) {
                $table->string('stripe_charge_id', 255)->nullable();
            }

            if (!Schema::hasColumn('orders', 'stripe_transfer_id')) {
                $table->string('stripe_transfer_id', 255)->nullable();
            }

            if (!Schema::hasColumn('orders', 'stripe_application_fee_amount')) {
                $table->decimal('stripe_application_fee_amount', 24, 2)->nullable();
            }

            if (!Schema::hasColumn('orders', 'stripe_currency')) {
                $table->string('stripe_currency', 10)->nullable();
            }
        });

        if (!Schema::hasTable('stripe_webhook_events')) {
            Schema::create('stripe_webhook_events', function (Blueprint $table) {
                $table->id();
                $table->string('event_id', 255)->unique();
                $table->string('type', 255)->nullable()->index();
                $table->string('account_id', 255)->nullable()->index();
                $table->longText('payload')->nullable();
                $table->string('status', 50)->default('pending')->index();
                $table->text('error')->nullable();
                $table->timestamp('processed_at')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('stripe_webhook_events');

        $this->dropColumnsSafely('orders', [
            'stripe_payment_intent_id',
            'stripe_charge_id',
            'stripe_transfer_id',
            'stripe_application_fee_amount',
            'stripe_currency',
        ]);

        $this->dropConnectColumns('delivery_men');
        $this->dropConnectColumns('vendors');
    }

    private function addConnectColumns(string $tableName): void
    {
        Schema::table($tableName, function (Blueprint $table) use ($tableName) {
            if (!Schema::hasColumn($tableName, 'stripe_account_id')) {
                $table->string('stripe_account_id', 255)->nullable()->unique();
            }

            if (!Schema::hasColumn($tableName, 'stripe_connect_status')) {
                $table->string('stripe_connect_status', 50)->nullable();
            }

            if (!Schema::hasColumn($tableName, 'stripe_charges_enabled')) {
                $table->boolean('stripe_charges_enabled')->default(false);
            }

            if (!Schema::hasColumn($tableName, 'stripe_payouts_enabled')) {
                $table->boolean('stripe_payouts_enabled')->default(false);
            }

            if (!Schema::hasColumn($tableName, 'stripe_details_submitted')) {
                $table->boolean('stripe_details_submitted')->default(false);
            }

            if (!Schema::hasColumn($tableName, 'stripe_requirements_due')) {
                $table->json('stripe_requirements_due')->nullable();
            }

            if (!Schema::hasColumn($tableName, 'stripe_onboarding_completed_at')) {
                $table->timestamp('stripe_onboarding_completed_at')->nullable();
            }
        });
    }

    private function dropConnectColumns(string $tableName): void
    {
        try {
            Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                $table->dropUnique($tableName . '_stripe_account_id_unique');
            });
        } catch (\Throwable $e) {
            // Index may not exist depending on rollback state.
        }

        $this->dropColumnsSafely($tableName, [
            'stripe_account_id',
            'stripe_connect_status',
            'stripe_charges_enabled',
            'stripe_payouts_enabled',
            'stripe_details_submitted',
            'stripe_requirements_due',
            'stripe_onboarding_completed_at',
        ]);
    }

    private function dropColumnsSafely(string $tableName, array $columns): void
    {
        $existingColumns = [];

        foreach ($columns as $column) {
            if (Schema::hasColumn($tableName, $column)) {
                $existingColumns[] = $column;
            }
        }

        if (!empty($existingColumns)) {
            Schema::table($tableName, function (Blueprint $table) use ($existingColumns) {
                $table->dropColumn($existingColumns);
            });
        }
    }
};
