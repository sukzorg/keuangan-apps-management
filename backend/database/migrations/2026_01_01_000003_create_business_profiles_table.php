<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('business_profiles', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('type', [
                'photography',
                'service_gadget',
                'internet_provider',
                'boarding_house',
                'app_development',
                'other'
            ]);
            $table->string('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
        // Data diisi via: php artisan db:seed --class=BusinessProfileSeeder
    }

    public function down(): void
    {
        Schema::dropIfExists('business_profiles');
    }
};