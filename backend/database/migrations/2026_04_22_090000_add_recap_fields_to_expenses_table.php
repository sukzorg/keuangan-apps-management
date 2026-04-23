<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            $table->foreignId('recap_id')
                ->nullable()
                ->after('id')
                ->constrained('monthly_recaps')
                ->nullOnDelete();

            $table->foreignId('payment_method_id')
                ->nullable()
                ->after('category_id')
                ->constrained('payment_methods')
                ->nullOnDelete();

            $table->text('notes')
                ->nullable()
                ->after('date');
        });
    }

    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            $table->dropForeign(['recap_id']);
            $table->dropForeign(['payment_method_id']);
            $table->dropColumn(['recap_id', 'payment_method_id', 'notes']);
        });
    }
};
