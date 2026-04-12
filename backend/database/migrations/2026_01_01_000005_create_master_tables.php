<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('debt_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('budget_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('priority', ['wajib', 'penting', 'keinginan']);
            $table->string('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('monthly_recaps', function (Blueprint $table) {
            $table->id();
            $table->integer('year');
            $table->integer('month');
            $table->enum('status', ['draft', 'final'])->default('draft');
            $table->date('recap_date')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
            $table->unique(['year', 'month']);
        });
        // Data diisi via: php artisan db:seed --class=MasterDataSeeder
    }

    public function down(): void
    {
        Schema::dropIfExists('monthly_recaps');
        Schema::dropIfExists('budget_categories');
        Schema::dropIfExists('debt_categories');
    }
};