<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\MonthlyRecap;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    public function index(Request $request)
    {
        $validated = $request->validate([
            'recap_id' => 'nullable|integer|exists:monthly_recaps,id',
            'date_from' => 'nullable|date',
            'date_to' => 'nullable|date|after_or_equal:date_from',
        ]);

        $query = Expense::with(['category', 'paymentMethod'])
            ->latest('date')
            ->latest('id');

        if (!empty($validated['recap_id'])) {
            $query->where('recap_id', (int) $validated['recap_id']);
        } else {
            $query->whereNull('recap_id');
        }

        if (!empty($validated['date_from'])) {
            $query->whereDate('date', '>=', $validated['date_from']);
        }

        if (!empty($validated['date_to'])) {
            $query->whereDate('date', '<=', $validated['date_to']);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'recap_id' => 'nullable|exists:monthly_recaps,id',
            'category_id' => 'required|exists:categories,id',
            'payment_method_id' => 'nullable|exists:payment_methods,id',
            'name' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0',
            'date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        if (!empty($validated['recap_id'])) {
            $this->ensureRecapEditable((int) $validated['recap_id']);
        }

        $expense = Expense::create($validated);

        return response()->json(
            $expense->load(['category', 'paymentMethod']),
            201
        );
    }

    public function show($id)
    {
        $expense = Expense::with(['category', 'paymentMethod', 'recap'])->find($id);

        if (!$expense) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        return response()->json($expense);
    }

    public function update(Request $request, $id)
    {
        $expense = Expense::with('recap')->find($id);

        if (!$expense) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        if ($expense->recap_id) {
            $this->ensureRecapEditable($expense->recap_id);
        }

        $validated = $request->validate([
            'recap_id' => 'sometimes|nullable|exists:monthly_recaps,id',
            'category_id' => 'sometimes|exists:categories,id',
            'payment_method_id' => 'sometimes|nullable|exists:payment_methods,id',
            'name' => 'sometimes|string|max:255',
            'amount' => 'sometimes|numeric|min:0',
            'date' => 'sometimes|date',
            'notes' => 'sometimes|nullable|string',
        ]);

        if (array_key_exists('recap_id', $validated) && !empty($validated['recap_id'])) {
            $this->ensureRecapEditable((int) $validated['recap_id']);
        }

        $expense->update($validated);

        return response()->json($expense->load(['category', 'paymentMethod']));
    }

    public function destroy($id)
    {
        $expense = Expense::with('recap')->find($id);

        if (!$expense) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        if ($expense->recap_id) {
            $this->ensureRecapEditable($expense->recap_id);
        }

        $expense->delete();

        return response()->json(['message' => 'Data berhasil dihapus']);
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
}
