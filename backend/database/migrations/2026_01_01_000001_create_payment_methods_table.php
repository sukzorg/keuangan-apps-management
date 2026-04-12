<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->string('name');              // Cash, GoPay, OVO, Dana, BCA, Mandiri, BRI, BNI
            $table->enum('type', [
                'cash',
                'e_wallet',                      // GoPay, OVO, Dana
                'bank_transfer'                  // BCA, Mandiri, BRI, BNI
            ]);
            $table->string('account_number')->nullable(); // nomor rekening / no HP ewallet
            $table->string('account_name')->nullable();   // nama pemilik
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_methods');
    }
};