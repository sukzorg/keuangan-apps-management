<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BudgetAllocation;
use App\Models\BusinessExpense;
use App\Models\BusinessIncomeEntry;
use App\Models\DebtItem;
use App\Models\DebtPayment;
use App\Models\Expense;
use App\Models\IncomeEntry;
use App\Models\MonthlyRecap;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;

class MonthlyRecapController extends Controller
{
    public function index()
    {
        $recaps = MonthlyRecap::orderBy('year', 'desc')
            ->orderBy('month', 'desc')
            ->get()
            ->map(function ($recap) {
                $recap->load([
                    'expenses',
                    'incomeEntries',
                    'businessIncomeEntries',
                    'debtPayments',
                    'budgetAllocations',
                    'businessExpenses',
                ]);

                return array_merge($recap->toArray(), [
                    'total_income' => $recap->total_income,
                    'total_expense' => $recap->total_expense,
                    'ending_balance' => $recap->ending_balance,
                ]);
            });

        return response()->json($recaps);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'year' => 'required|integer|min:2020|max:2099',
            'month' => 'required|integer|min:1|max:12',
            'recap_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $recap = MonthlyRecap::create([
            'year' => $validated['year'],
            'month' => $validated['month'],
            'status' => 'draft',
            'recap_date' => $validated['recap_date'] ?? null,
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json($recap, 201);
    }

    public function show($id)
    {
        $recap = MonthlyRecap::with([
            'expenses.category',
            'expenses.paymentMethod',
            'incomeEntries.incomeSource',
            'incomeEntries.paymentMethod',
            'businessIncomeEntries.business',
            'businessIncomeEntries.paymentMethod',
            'debtPayments.debtItem.debtCategory',
            'debtPayments.paymentMethod',
            'budgetAllocations.budgetCategory',
            'budgetAllocations.paymentMethod',
            'businessExpenses.business',
            'businessExpenses.expenseCategory',
            'businessExpenses.paymentMethod',
        ])->find($id);

        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        return response()->json(array_merge($recap->toArray(), [
            'total_income' => $recap->total_income,
            'total_expense' => $recap->total_expense,
            'ending_balance' => $recap->ending_balance,
            'summary' => $this->buildSummary($recap),
        ]));
    }

    public function finalize($id)
    {
        $recap = MonthlyRecap::find($id);
        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        $recap->update(['status' => 'final']);

        return response()->json([
            'message' => 'Rekap berhasil difinalisasi',
            'recap' => $recap,
        ]);
    }

    public function report($id)
    {
        $recap = MonthlyRecap::with([
            'expenses.category',
            'expenses.paymentMethod',
            'incomeEntries.incomeSource',
            'incomeEntries.paymentMethod',
            'businessIncomeEntries.business',
            'businessIncomeEntries.paymentMethod',
            'debtPayments.debtItem.debtCategory',
            'debtPayments.paymentMethod',
            'budgetAllocations.budgetCategory',
            'budgetAllocations.paymentMethod',
            'businessExpenses.business',
            'businessExpenses.expenseCategory',
            'businessExpenses.paymentMethod',
        ])->find($id);

        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        $debts = DebtItem::with('debtCategory')
            ->orderBy('status')
            ->orderByDesc('id')
            ->get();

        $expenses = $recap->expenses->map(fn ($expense) => [
            'id' => $expense->id,
            'name' => $expense->name,
            'amount' => $expense->amount,
            'date' => $expense->date,
            'notes' => $expense->notes,
            'category' => $expense->category ? [
                'id' => $expense->category->id,
                'name' => $expense->category->name,
            ] : null,
            'payment_method' => $expense->paymentMethod ? [
                'id' => $expense->paymentMethod->id,
                'name' => $expense->paymentMethod->name,
            ] : null,
        ]);

        $incomeEntries = $recap->incomeEntries->map(fn ($entry) => [
            'id' => $entry->id,
            'amount' => $entry->amount,
            'received_date' => $entry->received_date,
            'notes' => $entry->notes,
            'income_source' => [
                'id' => $entry->incomeSource->id,
                'name' => $entry->incomeSource->name,
            ],
            'payment_method' => [
                'id' => $entry->paymentMethod->id,
                'name' => $entry->paymentMethod->name,
            ],
        ]);

        $businessIncomes = $recap->businessIncomeEntries->map(fn ($entry) => [
            'id' => $entry->id,
            'description' => $entry->description,
            'amount' => $entry->amount,
            'received_date' => $entry->received_date,
            'notes' => $entry->notes,
            'business' => [
                'id' => $entry->business->id,
                'name' => $entry->business->name,
            ],
            'payment_method' => [
                'id' => $entry->paymentMethod->id,
                'name' => $entry->paymentMethod->name,
            ],
        ]);

        $businessExpenses = $recap->businessExpenses->map(fn ($expense) => [
            'id' => $expense->id,
            'description' => $expense->description,
            'amount' => $expense->amount,
            'expense_date' => $expense->expense_date,
            'notes' => $expense->notes,
            'business' => [
                'id' => $expense->business->id,
                'name' => $expense->business->name,
            ],
            'expense_category' => [
                'id' => $expense->expenseCategory->id,
                'name' => $expense->expenseCategory->name,
            ],
            'payment_method' => [
                'id' => $expense->paymentMethod->id,
                'name' => $expense->paymentMethod->name,
            ],
        ]);

        $budgetAllocations = $recap->budgetAllocations->map(fn ($allocation) => [
            'id' => $allocation->id,
            'planned_amount' => $allocation->planned_amount,
            'actual_amount' => $allocation->actual_amount,
            'notes' => $allocation->notes,
            'budget_category' => [
                'id' => $allocation->budgetCategory->id,
                'name' => $allocation->budgetCategory->name,
                'priority' => $allocation->budgetCategory->priority,
            ],
            'payment_method' => [
                'id' => $allocation->paymentMethod->id,
                'name' => $allocation->paymentMethod->name,
            ],
        ]);

        $debtPayments = $recap->debtPayments->map(fn ($payment) => [
            'id' => $payment->id,
            'amount_paid' => $payment->amount_paid,
            'payment_date' => $payment->payment_date,
            'status' => $payment->status,
            'notes' => $payment->notes,
            'debt_item' => [
                'id' => $payment->debtItem->id,
                'creditor_name' => $payment->debtItem->creditor_name,
                'monthly_installment' => $payment->debtItem->monthly_installment,
                'debt_category' => $payment->debtItem->debtCategory ? [
                    'id' => $payment->debtItem->debtCategory->id,
                    'name' => $payment->debtItem->debtCategory->name,
                ] : null,
            ],
            'payment_method' => [
                'id' => $payment->paymentMethod->id,
                'name' => $payment->paymentMethod->name,
            ],
        ]);

        $debtList = $debts->map(fn ($debt) => [
            'id' => $debt->id,
            'creditor_name' => $debt->creditor_name,
            'total_amount' => $debt->total_amount,
            'monthly_installment' => $debt->monthly_installment,
            'total_months' => $debt->total_months,
            'remaining_months' => $debt->remaining_months,
            'start_date' => $debt->start_date,
            'due_date' => $debt->due_date,
            'status' => $debt->status,
            'notes' => $debt->notes,
            'debt_category' => $debt->debtCategory ? [
                'id' => $debt->debtCategory->id,
                'name' => $debt->debtCategory->name,
            ] : null,
        ]);

        return response()->json([
            'id' => $recap->id,
            'year' => $recap->year,
            'month' => $recap->month,
            'status' => $recap->status,
            'notes' => $recap->notes,
            'recap_date' => $recap->recap_date,
            'total_income' => $recap->total_income,
            'total_expense' => $recap->total_expense,
            'total_debt' => $debts->where('status', 'active')->sum('total_amount'),
            'total_budget' => $recap->budgetAllocations->sum('planned_amount'),
            'ending_balance' => $recap->ending_balance,
            'expenses' => $expenses,
            'income_entries' => $incomeEntries,
            'business_incomes' => $businessIncomes,
            'business_expenses' => $businessExpenses,
            'budget_allocations' => $budgetAllocations,
            'debts' => $debtList,
            'debt_payments' => $debtPayments,
        ]);
    }

    public function addIncomeEntry(Request $request, $id)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $validated = $request->validate([
            'income_source_id' => 'required|exists:income_sources,id',
            'amount' => 'required|numeric|min:0',
            'received_date' => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'notes' => 'nullable|string',
        ]);

        $entry = IncomeEntry::create(array_merge($validated, [
            'recap_id' => $id,
        ]));

        return response()->json($entry->load(['incomeSource', 'paymentMethod']), 201);
    }

    public function listIncomeEntries($id)
    {
        $this->findRecap($id);

        $entries = IncomeEntry::with(['incomeSource', 'paymentMethod'])
            ->where('recap_id', $id)
            ->get();

        return response()->json([
            'entries' => $entries,
            'total' => $entries->sum('amount'),
        ]);
    }

    public function updateIncomeEntry(Request $request, $id, $entryId)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $entry = IncomeEntry::where('recap_id', $id)->find($entryId);
        if (!$entry) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $validated = $request->validate([
            'income_source_id' => 'sometimes|exists:income_sources,id',
            'amount' => 'sometimes|numeric|min:0',
            'received_date' => 'sometimes|date',
            'payment_method_id' => 'sometimes|exists:payment_methods,id',
            'notes' => 'sometimes|nullable|string',
        ]);

        $entry->update($validated);

        return response()->json($entry->load(['incomeSource', 'paymentMethod']));
    }

    public function deleteIncomeEntry($id, $entryId)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $entry = IncomeEntry::where('recap_id', $id)->find($entryId);
        if (!$entry) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $entry->delete();

        return response()->json(['message' => 'Income entry berhasil dihapus']);
    }

    public function addBusinessIncome(Request $request, $id)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $validated = $request->validate([
            'business_id' => 'required|exists:business_profiles,id',
            'description' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'received_date' => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'notes' => 'nullable|string',
        ]);

        $entry = BusinessIncomeEntry::create(array_merge($validated, [
            'recap_id' => $id,
        ]));

        return response()->json($entry->load(['business', 'paymentMethod']), 201);
    }

    public function listBusinessIncomes($id)
    {
        $this->findRecap($id);

        $entries = BusinessIncomeEntry::with(['business', 'paymentMethod'])
            ->where('recap_id', $id)
            ->get();

        return response()->json([
            'entries' => $entries,
            'total' => $entries->sum('amount'),
        ]);
    }

    public function updateBusinessIncome(Request $request, $id, $entryId)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $entry = BusinessIncomeEntry::where('recap_id', $id)->find($entryId);
        if (!$entry) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $validated = $request->validate([
            'business_id' => 'sometimes|exists:business_profiles,id',
            'description' => 'sometimes|string',
            'amount' => 'sometimes|numeric|min:0',
            'received_date' => 'sometimes|date',
            'payment_method_id' => 'sometimes|exists:payment_methods,id',
            'notes' => 'sometimes|nullable|string',
        ]);

        $entry->update($validated);

        return response()->json($entry->load(['business', 'paymentMethod']));
    }

    public function deleteBusinessIncome($id, $entryId)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $entry = BusinessIncomeEntry::where('recap_id', $id)->find($entryId);
        if (!$entry) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $entry->delete();

        return response()->json(['message' => 'Business income entry berhasil dihapus']);
    }

    public function updateDebtPayment(Request $request, $id, $paymentId)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $payment = DebtPayment::with('debtItem')
            ->where('recap_id', $id)
            ->find($paymentId);

        if (!$payment) {
            return response()->json(['message' => 'Pembayaran hutang tidak ditemukan'], 404);
        }

        $validated = $request->validate([
            'amount_paid' => 'sometimes|numeric|min:0',
            'payment_date' => 'sometimes|date',
            'payment_method_id' => 'sometimes|exists:payment_methods,id',
            'status' => 'sometimes|in:paid,partial,skipped',
            'notes' => 'sometimes|nullable|string',
        ]);

        $payment->update($validated);
        $payment->debtItem->recalculateProgress();

        return response()->json($payment->load(['debtItem.debtCategory', 'paymentMethod']));
    }

    public function deleteDebtPayment($id, $paymentId)
    {
        $recap = $this->findRecap($id);
        $this->ensureRecapEditable($recap);

        $payment = DebtPayment::with('debtItem')
            ->where('recap_id', $id)
            ->find($paymentId);

        if (!$payment) {
            return response()->json(['message' => 'Pembayaran hutang tidak ditemukan'], 404);
        }

        $debtItem = $payment->debtItem;
        $payment->delete();
        $debtItem->recalculateProgress();

        return response()->json(['message' => 'Pembayaran hutang berhasil dihapus']);
    }

    private function findRecap(int $id): MonthlyRecap
    {
        $recap = MonthlyRecap::find($id);

        if (!$recap) {
            throw new HttpResponseException(response()->json([
                'message' => 'Rekap tidak ditemukan',
            ], 404));
        }

        return $recap;
    }

    private function ensureRecapEditable(MonthlyRecap $recap): void
    {
        if (in_array($recap->status, ['final', 'finalized'], true)) {
            throw new HttpResponseException(response()->json([
                'message' => 'Rekap yang sudah difinalisasi tidak dapat diubah.',
            ], 422));
        }
    }

    private function buildSummary(MonthlyRecap $recap): array
    {
        return [
            'income_by_source' => $recap->incomeEntries
                ->groupBy(fn ($item) => $item->incomeSource->name ?? 'Unknown')
                ->map->sum('amount'),
            'expense_by_type' => [
                'expense' => $recap->expenses->sum('amount'),
                'debt' => $recap->debtPayments->sum('amount_paid'),
                'budget' => $recap->budgetAllocations->sum('actual_amount'),
                'business' => $recap->businessExpenses->sum('amount'),
            ],
        ];
    }
}
