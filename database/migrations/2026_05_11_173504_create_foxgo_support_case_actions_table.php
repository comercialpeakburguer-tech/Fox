<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('foxgo_support_case_actions')) {
            Schema::create('foxgo_support_case_actions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('case_id')->index();
                $table->unsignedBigInteger('admin_id')->nullable()->index();
                $table->unsignedBigInteger('department_id')->nullable()->index();
                $table->string('action_type')->index();
                $table->longText('description')->nullable();
                $table->text('old_value')->nullable();
                $table->text('new_value')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->index(['case_id', 'action_type']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_support_case_actions');
    }
};
