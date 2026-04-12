<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Income Entries (Gaji, Investasi, dll) ───────────────────
        Schema::create('income_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('recap_id');
            $table->unsignedBigInteger('income_source_id');
            $table->decimal('amount', 15, 2);
            $table->date('received_date');
            $table->unsignedBigInteger('payment_method_id');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('recap_id')
                  ->references('id')->on('monthly_recaps')
                  ->onDelete('cascade');

            $table->foreign('income_source_id')
                  ->references('id')->on('income_sources')
                  ->onDelete('restrict');

            $table->foreign('payment_method_id')
                  ->references('id')->on('payment_methods')
                  ->onDelete('restrict');
        });

        // ── Business Income Entries (Income per Bisnis) ─────────────
        Schema::create('business_income_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('recap_id');
            $table->unsignedBigInteger('business_id');
            $table->string('description');
            $table->decimal('amount', 15, 2);
            $table->date('received_date');
            $table->unsignedBigInteger('payment_method_id');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('recap_id')
                  ->references('id')->on('monthly_recaps')
                  ->onDelete('cascade');

            $table->foreign('business_id')
                  ->references('id')->on('business_profiles')
                  ->onDelete('restrict');

            $table->foreign('payment_method_id')
                  ->references('id')->on('payment_methods')
                  ->onDelete('restrict');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('business_income_entries');
        Schema::dropIfExists('income_entries');
    }
};