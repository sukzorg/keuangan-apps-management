<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MonthlyRecap;
use App\Models\IncomeEntry;
use App\Models\BusinessIncomeEntry;
use App\Models\DebtPayment;
use App\Models\BudgetAllocation;
use App\Models\BusinessExpense;
use Illuminate\Http\Request;

class MonthlyRecapController extends Controller
{
    // GET /monthly-recaps
    public function index()
    {
        $recaps = MonthlyRecap::orderBy('year', 'desc')
                              ->orderBy('month', 'desc')
                              ->get()
                              ->map(function ($r) {
                                  $r->load([
                                      'incomeEntries',
                                      'businessIncomeEntries',
                                      'debtPayments',
                                      'budgetAllocations',
                                      'businessExpenses',
                                  ]);
                                  return array_merge($r->toArray(), [
                                      'total_income'   => $r->total_income,
                                      'total_expense'  => $r->total_expense,
                                      'ending_balance' => $r->ending_balance,
                                  ]);
                              });

        return response()->json($recaps);
    }

    // POST /monthly-recaps
    public function store(Request $request)
    {
        $request->validate([
            'year'       => 'required|integer|min:2020|max:2099',
            'month'      => 'required|integer|min:1|max:12',
            'recap_date' => 'nullable|date',
            'notes'      => 'nullable|string',
        ]);

        $recap = MonthlyRecap::create([
            'year'       => $request->year,
            'month'      => $request->month,
            'status'     => 'draft',
            'recap_date' => $request->recap_date,
            'notes'      => $request->notes,
        ]);

        return response()->json($recap, 201);
    }

    // GET /monthly-recaps/{id}
    public function show($id)
    {
        $recap = MonthlyRecap::with([
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
            'total_income'   => $recap->total_income,
            'total_expense'  => $recap->total_expense,
            'ending_balance' => $recap->ending_balance,
            'summary'        => $this->buildSummary($recap),
        ]));
    }

    // PUT /monthly-recaps/{id}/finalize
    public function finalize($id)
    {
        $recap = MonthlyRecap::find($id);
        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        // BUGFIX: status harus 'finalized' bukan 'final'
        $recap->update(['status' => 'finalized']);
        return response()->json(['message' => 'Rekap berhasil difinalisasi', 'recap' => $recap]);
    }

    // GET /monthly-recaps/{id}/report
    // ── Struktur DISESUAIKAN dengan Flutter RecapDetailPage ──────────
    public function report($id)
    {
        $recap = MonthlyRecap::with([
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

        // Ambil semua hutang aktif
        $debts = \App\Models\DebtItem::where('status', 'active')->get();

        // Format income_entries → Flutter baca 'income_source.name'
        $incomeEntries = $recap->incomeEntries->map(fn($i) => [
            'id'             => $i->id,
            'amount'         => $i->amount,
            'received_date'  => $i->received_date,
            'notes'          => $i->notes,
            'income_source'  => [
                'id'   => $i->incomeSource->id,
                'name' => $i->incomeSource->name,
            ],
            'payment_method' => [
                'id'   => $i->paymentMethod->id,
                'name' => $i->paymentMethod->name,
            ],
        ]);

        // Format business_incomes → Flutter baca 'business.name'
        $businessIncomes = $recap->businessIncomeEntries->map(fn($b) => [
            'id'             => $b->id,
            'description'    => $b->description,
            'amount'         => $b->amount,
            'received_date'  => $b->received_date,
            'notes'          => $b->notes,
            'business'       => [
                'id'   => $b->business->id,
                'name' => $b->business->name,
            ],
            'payment_method' => [
                'id'   => $b->paymentMethod->id,
                'name' => $b->paymentMethod->name,
            ],
        ]);

        // Format budget_allocations → Flutter baca 'budget_category.name'
        $budgetAllocations = $recap->budgetAllocations->map(fn($b) => [
            'id'              => $b->id,
            'planned_amount'  => $b->planned_amount,
            'actual_amount'   => $b->actual_amount,
            'notes'           => $b->notes,
            'budget_category' => [
                'id'       => $b->budgetCategory->id,
                'name'     => $b->budgetCategory->name,
                'priority' => $b->budgetCategory->priority,
            ],
            'payment_method'  => [
                'id'   => $b->paymentMethod->id,
                'name' => $b->paymentMethod->name,
            ],
        ]);

        // Format debts → Flutter tampilkan progress cicilan
        $debtList = $debts->map(fn($d) => [
            'id'                  => $d->id,
            'creditor_name'       => $d->creditor_name,
            'total_amount'        => $d->total_amount,
            'monthly_installment' => $d->monthly_installment,
            'total_months'        => $d->total_months,
            'remaining_months'    => $d->remaining_months,
            'status'              => $d->status,
        ]);

        return response()->json([
            // Info rekap
            'id'         => $recap->id,
            'year'       => $recap->year,
            'month'      => $recap->month,
            'status'     => $recap->status,
            'notes'      => $recap->notes,
            'recap_date' => $recap->recap_date,

            // Angka total — untuk Summary tab
            'total_income'   => $recap->total_income,
            'total_expense'  => $recap->total_expense,
            'total_debt'     => $debts->sum('total_amount'),
            'total_budget'   => $recap->budgetAllocations->sum('planned_amount'),
            'ending_balance' => $recap->ending_balance,

            // Data list — untuk masing-masing tab di Flutter
            'income_entries'     => $incomeEntries,
            'business_incomes'   => $businessIncomes,
            'budget_allocations' => $budgetAllocations,
            'debts'              => $debtList,
        ]);
    }

    // ─────────────────────────────────────────────────────────────────
    // INCOME ENTRIES
    // ─────────────────────────────────────────────────────────────────

    public function addIncomeEntry(Request $request, $id)
    {
        $recap = MonthlyRecap::find($id);
        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        $request->validate([
            'income_source_id'  => 'required|exists:income_sources,id',
            'amount'            => 'required|numeric|min:0',
            'received_date'     => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'notes'             => 'nullable|string',
        ]);

        $entry = IncomeEntry::create(array_merge(
            $request->all(),
            ['recap_id' => $id]
        ));

        return response()->json(
            $entry->load(['incomeSource', 'paymentMethod']),
            201
        );
    }

    public function listIncomeEntries($id)
    {
        $recap = MonthlyRecap::find($id);
        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        $entries = IncomeEntry::with(['incomeSource', 'paymentMethod'])
            ->where('recap_id', $id)
            ->get();

        return response()->json([
            'entries' => $entries,
            'total'   => $entries->sum('amount'),
        ]);
    }

    public function deleteIncomeEntry($id, $entryId)
    {
        $entry = IncomeEntry::where('recap_id', $id)->where('id', $entryId)->first();
        if (!$entry) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $entry->delete();
        return response()->json(['message' => 'Income entry berhasil dihapus']);
    }

    // ─────────────────────────────────────────────────────────────────
    // BUSINESS INCOME ENTRIES
    // ─────────────────────────────────────────────────────────────────

    public function addBusinessIncome(Request $request, $id)
    {
        $recap = MonthlyRecap::find($id);
        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        $request->validate([
            'business_id'       => 'required|exists:business_profiles,id',
            'description'       => 'required|string',
            'amount'            => 'required|numeric|min:0',
            'received_date'     => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'notes'             => 'nullable|string',
        ]);

        $entry = BusinessIncomeEntry::create(array_merge(
            $request->all(),
            ['recap_id' => $id]
        ));

        return response()->json(
            $entry->load(['business', 'paymentMethod']),
            201
        );
    }

    public function listBusinessIncomes($id)
    {
        $recap = MonthlyRecap::find($id);
        if (!$recap) {
            return response()->json(['message' => 'Rekap tidak ditemukan'], 404);
        }

        $entries = BusinessIncomeEntry::with(['business', 'paymentMethod'])
            ->where('recap_id', $id)
            ->get();

        return response()->json([
            'entries' => $entries,
            'total'   => $entries->sum('amount'),
        ]);
    }

    public function deleteBusinessIncome($id, $entryId)
    {
        $entry = BusinessIncomeEntry::where('recap_id', $id)->where('id', $entryId)->first();
        if (!$entry) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $entry->delete();
        return response()->json(['message' => 'Business income entry berhasil dihapus']);
    }

    // ─────────────────────────────────────────────────────────────────
    // PRIVATE HELPER
    // ─────────────────────────────────────────────────────────────────

    private function buildSummary(MonthlyRecap $recap): array
    {
        return [
            'income_by_source' => $recap->incomeEntries
                ->groupBy(fn($i) => $i->incomeSource->name ?? 'Unknown')
                ->map->sum('amount'),
            'expense_by_type'  => [
                'debt'     => $recap->debtPayments->sum('amount_paid'),
                'budget'   => $recap->budgetAllocations->sum('actual_amount'),
                'business' => $recap->businessExpenses->sum('amount'),
            ],
        ];
    }
}