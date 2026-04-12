<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Debt Items ───────────────────────────────────────────────
        // Master data hutang yang dimiliki
        Schema::create('debt_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('debt_category_id');
            $table->string('creditor_name');                 // nama pemberi hutang / lembaga
            $table->decimal('total_amount', 15, 2);          // total hutang awal
            $table->decimal('monthly_installment', 15, 2);   // cicilan per bulan
            $table->integer('total_months');                  // total bulan cicilan
            $table->integer('remaining_months');              // sisa bulan cicilan
            $table->date('start_date');                       // mulai cicilan
            $table->date('due_date');                         // tanggal jatuh tempo tiap bulan
            $table->enum('status', ['active', 'paid_off', 'overdue'])->default('active');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('debt_category_id')->references('id')->on('debt_categories')->onDelete('restrict');
        });

        // ── Debt Payments ────────────────────────────────────────────
        // Riwayat pembayaran cicilan per bulan
        Schema::create('debt_payments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('recap_id');          // FK ke monthly_recaps
            $table->unsignedBigInteger('debt_item_id');      // FK ke debt_items
            $table->decimal('amount_paid', 15, 2);           // jumlah dibayar bulan ini
            $table->date('payment_date');
            $table->unsignedBigInteger('payment_method_id'); // dibayar via apa
            $table->enum('status', ['paid', 'partial', 'skipped'])->default('paid');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->foreign('recap_id')->references('id')->on('monthly_recaps')->onDelete('cascade');
            $table->foreign('debt_item_id')->references('id')->on('debt_items')->onDelete('restrict');
            $table->foreign('payment_method_id')->references('id')->on('payment_methods')->onDelete('restrict');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('debt_payments');
        Schema::dropIfExists('debt_items');
    }
};