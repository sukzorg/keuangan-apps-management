<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recap_expenses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('recap_id')->constrained('monthly_recaps')->cascadeOnDelete();
            $table->foreignId('category_id')->constrained('categories')->restrictOnDelete();
            $table->string('name');
            $table->decimal('amount', 15, 2);
            $table->date('date');
            $table->foreignId('payment_method_id')->nullable()->constrained('payment_methods')->nullOnDelete();
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        $legacyRecapExpenses = DB::table('expenses')
            ->whereNotNull('recap_id')
            ->orderBy('id')
            ->get([
                'recap_id',
                'category_id',
                'name',
                'amount',
                'date',
                'payment_method_id',
                'notes',
                'created_at',
                'updated_at',
            ]);

        if ($legacyRecapExpenses->isNotEmpty()) {
            DB::table('recap_expenses')->insert(
                $legacyRecapExpenses
                    ->map(fn ($item) => [
                        'recap_id' => $item->recap_id,
                        'category_id' => $item->category_id,
                        'name' => $item->name,
                        'amount' => $item->amount,
                        'date' => $item->date,
                        'payment_method_id' => $item->payment_method_id,
                        'notes' => $item->notes,
                        'created_at' => $item->created_at,
                        'updated_at' => $item->updated_at,
                    ])
                    ->all()
            );
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('recap_expenses');
    }
};
