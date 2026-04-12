<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Budget Allocations ───────────────────────────────────────
        // Alokasi budget bulanan per kategori (planning bulan depan)
        Schema::create('budget_allocations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('recap_id');
            $table->unsignedBigInteger('budget_category_id');
            $table->decimal('planned_amount', 15, 2);        // direncanakan
            $table->decimal('actual_amount', 15, 2)->default(0); // realisasi
            $table->unsignedBigInteger('payment_method_id'); // dibayar/pindah ke mana
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('recap_id')->references('id')->on('monthly_recaps')->onDelete('cascade');
            $table->foreign('budget_category_id')->references('id')->on('budget_categories')->onDelete('restrict');
            $table->foreign('payment_method_id')->references('id')->on('payment_methods')->onDelete('restrict');
        });

        // ── Business Expenses ────────────────────────────────────────
        // Pengeluaran operasional per bisnis dalam periode rekap
        Schema::create('business_expenses', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('recap_id');
            $table->unsignedBigInteger('business_id');
            $table->unsignedBigInteger('business_expense_category_id');
            $table->string('description');                   // keterangan detail
            $table->decimal('amount', 15, 2);
            $table->date('expense_date');
            $table->unsignedBigInteger('payment_method_id'); // dibayar dari mana
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('recap_id')->references('id')->on('monthly_recaps')->onDelete('cascade');
            $table->foreign('business_id')->references('id')->on('business_profiles')->onDelete('restrict');
            $table->foreign('business_expense_category_id')->references('id')->on('business_expense_categories')->onDelete('restrict');
            $table->foreign('payment_method_id')->references('id')->on('payment_methods')->onDelete('restrict');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('business_expenses');
        Schema::dropIfExists('budget_allocations');
    }
};