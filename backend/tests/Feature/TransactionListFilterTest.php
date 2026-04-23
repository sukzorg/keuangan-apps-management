<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Expense;
use App\Models\Income;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TransactionListFilterTest extends TestCase
{
    use RefreshDatabase;

    public function test_expense_index_can_filter_by_date_range(): void
    {
        $category = Category::create([
            'name' => 'Transport',
            'type' => 'expense',
            'is_active' => true,
        ]);

        Expense::create([
            'category_id' => $category->id,
            'name' => 'Isi BBM Lama',
            'amount' => 100000,
            'date' => '2026-03-01',
        ]);

        Expense::create([
            'category_id' => $category->id,
            'name' => 'Isi BBM Baru',
            'amount' => 150000,
            'date' => '2026-04-20',
        ]);

        $response = $this->getJson('/api/expenses?date_from=2026-04-01&date_to=2026-04-30');

        $response
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.name', 'Isi BBM Baru');
    }

    public function test_expense_index_hides_legacy_recap_expenses_from_daily_list(): void
    {
        $category = Category::create([
            'name' => 'Belanja',
            'type' => 'expense',
            'is_active' => true,
        ]);

        Expense::create([
            'category_id' => $category->id,
            'name' => 'Belanja Harian',
            'amount' => 50000,
            'date' => '2026-04-21',
        ]);

        $recapId = \App\Models\MonthlyRecap::create([
            'year' => 2026,
            'month' => 4,
            'status' => 'draft',
        ])->id;

        Expense::create([
            'recap_id' => $recapId,
            'category_id' => $category->id,
            'name' => 'Legacy Recap Expense',
            'amount' => 125000,
            'date' => '2026-04-21',
        ]);

        $response = $this->getJson('/api/expenses');

        $response
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.name', 'Belanja Harian');
    }

    public function test_income_index_can_filter_by_date_range(): void
    {
        Income::create([
            'name' => 'Bonus Lama',
            'amount' => 500000,
            'date' => '2026-03-05',
        ]);

        Income::create([
            'name' => 'Bonus Baru',
            'amount' => 750000,
            'date' => '2026-04-18',
        ]);

        $response = $this->getJson('/api/incomes?date_from=2026-04-01&date_to=2026-04-30');

        $response
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonPath('0.name', 'Bonus Baru');
    }
}
