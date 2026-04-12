<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('business_expense_categories', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('business_id');
            $table->string('name');
            $table->string('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('business_id')
                  ->references('id')->on('business_profiles')
                  ->onDelete('cascade');
        });
        // Data diisi via: php artisan db:seed --class=BusinessProfileSeeder
    }

    public function down(): void
    {
        Schema::dropIfExists('business_expense_categories');
    }
};