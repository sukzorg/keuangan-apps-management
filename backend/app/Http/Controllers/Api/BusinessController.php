<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BusinessExpense;
use App\Models\BusinessExpenseCategory;
use App\Models\BusinessIncomeEntry;
use App\Models\BusinessProfile;
use App\Models\MonthlyRecap;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;

class BusinessController extends Controller
{
    public function index()
    {
        return response()->json(
            BusinessProfile::with('expenseCategories')
                ->where('is_active', true)
                ->get()
        );
    }

    public function addIncome(Request $request, $id)
    {
        $business = BusinessProfile::find($id);
        if (!$business) {
            return response()->json(['message' => 'Bisnis tidak ditemukan'], 404);
        }

        $validated = $request->validate([
            'recap_id' => 'required|exists:monthly_recaps,id',
            'description' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'received_date' => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'notes' => 'nullable|string',
        ]);

        $this->ensureRecapEditable((int) $validated['recap_id']);

        $entry = BusinessIncomeEntry::create(array_merge($validated, [
            'business_id' => $id,
        ]));

        return response()->json($entry->load(['business', 'paymentMethod']), 201);
    }

    public function addExpense(Request $request, $id)
    {
        $business = BusinessProfile::find($id);
        if (!$business) {
            return response()->json(['message' => 'Bisnis tidak ditemukan'], 404);
        }

        $validated = $request->validate([
            'recap_id' => 'required|exists:monthly_recaps,id',
            'business_expense_category_id' => 'required|exists:business_expense_categories,id',
            'description' => 'required|string',
            'amount' => 'required|numeric|min:0',
            'expense_date' => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'notes' => 'nullable|string',
        ]);

        $this->ensureRecapEditable((int) $validated['recap_id']);
        $this->ensureCategoryBelongsToBusiness((int) $validated['business_expense_category_id'], (int) $id);

        $expense = BusinessExpense::create(array_merge($validated, [
            'business_id' => $id,
        ]));

        return response()->json(
            $expense->load(['business', 'expenseCategory', 'paymentMethod']),
            201
        );
    }

    public function updateExpense(Request $request, $id, $expenseId)
    {
        $expense = BusinessExpense::with('recap')->where('business_id', $id)->find($expenseId);
        if (!$expense) {
            return response()->json(['message' => 'Pengeluaran bisnis tidak ditemukan'], 404);
        }

        $this->ensureRecapEditable($expense->recap_id);

        $validated = $request->validate([
            'business_expense_category_id' => 'sometimes|exists:business_expense_categories,id',
            'description' => 'sometimes|string',
            'amount' => 'sometimes|numeric|min:0',
            'expense_date' => 'sometimes|date',
            'payment_method_id' => 'sometimes|exists:payment_methods,id',
            'notes' => 'sometimes|nullable|string',
        ]);

        if (!empty($validated['business_expense_category_id'])) {
            $this->ensureCategoryBelongsToBusiness((int) $validated['business_expense_category_id'], (int) $id);
        }

        $expense->update($validated);

        return response()->json($expense->load(['business', 'expenseCategory', 'paymentMethod']));
    }

    public function deleteExpense($id, $expenseId)
    {
        $expense = BusinessExpense::with('recap')->where('business_id', $id)->find($expenseId);
        if (!$expense) {
            return response()->json(['message' => 'Pengeluaran bisnis tidak ditemukan'], 404);
        }

        $this->ensureRecapEditable($expense->recap_id);
        $expense->delete();

        return response()->json(['message' => 'Pengeluaran bisnis berhasil dihapus']);
    }

    private function ensureRecapEditable(int $recapId): void
    {
        $recap = MonthlyRecap::find($recapId);

        if ($recap && in_array($recap->status, ['final', 'finalized'], true)) {
            throw new HttpResponseException(response()->json([
                'message' => 'Rekap yang sudah difinalisasi tidak dapat diubah.',
            ], 422));
        }
    }

    private function ensureCategoryBelongsToBusiness(int $categoryId, int $businessId): void
    {
        $exists = BusinessExpenseCategory::where('id', $categoryId)
            ->where('business_id', $businessId)
            ->exists();

        if (!$exists) {
            throw new HttpResponseException(response()->json([
                'message' => 'Kategori pengeluaran bisnis tidak sesuai dengan bisnis yang dipilih.',
            ], 422));
        }
    }
}
