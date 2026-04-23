<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\DebtCategory;
use App\Models\DebtItem;
use App\Models\MonthlyRecap;
use App\Models\PaymentMethod;
use App\Models\RecapExpense;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RecapMutationValidationTest extends TestCase
{
    use RefreshDatabase;

    public function test_finalized_recap_rejects_new_expense_entry(): void
    {
        $recap = MonthlyRecap::create([
            'year' => 2026,
            'month' => 4,
            'status' => 'final',
        ]);

        $category = Category::create([
            'name' => 'Belanja Harian',
            'type' => 'expense',
            'is_active' => true,
        ]);

        $paymentMethod = PaymentMethod::create([
            'name' => 'Cash',
            'type' => 'cash',
            'is_active' => true,
        ]);

        $response = $this->postJson("/api/monthly-recaps/{$recap->id}/expenses", [
            'category_id' => $category->id,
            'payment_method_id' => $paymentMethod->id,
            'name' => 'Belanja Mingguan',
            'amount' => 250000,
            'date' => '2026-04-23',
            'notes' => 'Tes validasi final',
        ]);

        $response
            ->assertStatus(422)
            ->assertJsonPath(
                'message',
                'Rekap yang sudah difinalisasi tidak dapat diubah.'
            );

        $this->assertDatabaseCount('recap_expenses', 0);
    }

    public function test_updating_debt_payment_recalculates_remaining_months(): void
    {
        $recap = MonthlyRecap::create([
            'year' => 2026,
            'month' => 4,
            'status' => 'draft',
        ]);

        $debtCategory = DebtCategory::create([
            'name' => 'KPR',
            'description' => 'Tes hutang',
            'is_active' => true,
        ]);

        $paymentMethod = PaymentMethod::create([
            'name' => 'Transfer',
            'type' => 'bank_transfer',
            'is_active' => true,
        ]);

        $debt = DebtItem::create([
            'debt_category_id' => $debtCategory->id,
            'creditor_name' => 'Bank Test',
            'total_amount' => 1200000,
            'monthly_installment' => 100000,
            'total_months' => 12,
            'remaining_months' => 12,
            'start_date' => '2026-01-01',
            'due_date' => '2026-01-25',
            'status' => 'active',
        ]);

        $createPayment = $this->postJson("/api/debts/{$debt->id}/pay", [
            'recap_id' => $recap->id,
            'amount_paid' => 100000,
            'payment_date' => '2026-04-23',
            'payment_method_id' => $paymentMethod->id,
            'status' => 'paid',
        ]);

        $createPayment->assertCreated();
        $debt->refresh();
        $this->assertSame(11, $debt->remaining_months);

        $paymentId = $createPayment->json('id');

        $updatePayment = $this->putJson(
            "/api/monthly-recaps/{$recap->id}/debt-payments/{$paymentId}",
            [
                'amount_paid' => 0,
                'payment_date' => '2026-04-23',
                'payment_method_id' => $paymentMethod->id,
                'status' => 'skipped',
            ]
        );

        $updatePayment->assertOk();
        $debt->refresh();

        $this->assertSame(12, $debt->remaining_months);
        $this->assertSame('active', $debt->status);
    }

    public function test_recap_report_includes_monthly_expenses_in_total(): void
    {
        $recap = MonthlyRecap::create([
            'year' => 2026,
            'month' => 4,
            'status' => 'draft',
        ]);

        $category = Category::create([
            'name' => 'Transport',
            'type' => 'expense',
            'is_active' => true,
        ]);

        $paymentMethod = PaymentMethod::create([
            'name' => 'Dana',
            'type' => 'e_wallet',
            'is_active' => true,
        ]);

        RecapExpense::create([
            'recap_id' => $recap->id,
            'category_id' => $category->id,
            'payment_method_id' => $paymentMethod->id,
            'name' => 'Isi BBM',
            'amount' => 150000,
            'date' => '2026-04-23',
            'notes' => 'Tes laporan expense',
        ]);

        $response = $this->getJson("/api/monthly-recaps/{$recap->id}/report");

        $response
            ->assertOk()
            ->assertJsonCount(1, 'expenses')
            ->assertJsonPath('expenses.0.name', 'Isi BBM')
            ->assertJsonPath('total_expense', 150000);
    }
}
