<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('foxgo_support_case_evidences')) {
            Schema::create('foxgo_support_case_evidences', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('case_id')->index();
                $table->string('uploaded_by_type')->nullable()->index();
                $table->unsignedBigInteger('uploaded_by_id')->nullable()->index();
                $table->string('evidence_type')->nullable()->index();
                $table->text('file')->nullable();
                $table->longText('note')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->index(['case_id', 'evidence_type']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('foxgo_support_case_evidences');
    }
};
