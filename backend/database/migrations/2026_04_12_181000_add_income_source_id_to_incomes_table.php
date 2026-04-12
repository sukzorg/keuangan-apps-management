<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('incomes', 'income_source_id')) {
            Schema::table('incomes', function (Blueprint $table) {
                $table->foreignId('income_source_id')
                    ->nullable()
                    ->after('category_id')
                    ->constrained('income_sources')
                    ->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('incomes', 'income_source_id')) {
            Schema::table('incomes', function (Blueprint $table) {
                $table->dropForeign(['income_source_id']);
                $table->dropColumn('income_source_id');
            });
        }
    }
};
