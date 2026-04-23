<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BudgetAllocation;
use App\Models\MonthlyRecap;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'recap_id' => 'required|exists:monthly_recaps,id',
            'budget_category_id' => 'required|exists:budget_categories,id',
            'planned_amount' => 'required|numeric|min:0',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'notes' => 'nullable|string',
        ]);

        $this->ensureRecapEditable((int) $validated['recap_id']);

        $allocation = BudgetAllocation::create($validated);

        return response()->json(
            $allocation->load(['budgetCategory', 'paymentMethod']),
            201
        );
    }

    public function update(Request $request, $id)
    {
        $allocation = BudgetAllocation::with('recap')->find($id);
        if (!$allocation) {
            return response()->json(['message' => 'Alokasi tidak ditemukan'], 404);
        }

        $this->ensureRecapEditable($allocation->recap_id);

        $validated = $request->validate([
            'budget_category_id' => 'sometimes|exists:budget_categories,id',
            'planned_amount' => 'sometimes|numeric|min:0',
            'actual_amount' => 'sometimes|numeric|min:0',
            'payment_method_id' => 'sometimes|exists:payment_methods,id',
            'notes' => 'sometimes|nullable|string',
        ]);

        $allocation->update($validated);

        return response()->json($allocation->load(['budgetCategory', 'paymentMethod']));
    }

    public function updateActual(Request $request, $id)
    {
        $allocation = BudgetAllocation::with('recap')->find($id);
        if (!$allocation) {
            return response()->json(['message' => 'Alokasi tidak ditemukan'], 404);
        }

        $this->ensureRecapEditable($allocation->recap_id);

        $validated = $request->validate([
            'actual_amount' => 'required|numeric|min:0',
        ]);

        $allocation->update($validated);

        return response()->json($allocation->load(['budgetCategory', 'paymentMethod']));
    }

    public function destroy($id)
    {
        $allocation = BudgetAllocation::with('recap')->find($id);
        if (!$allocation) {
            return response()->json(['message' => 'Alokasi tidak ditemukan'], 404);
        }

        $this->ensureRecapEditable($allocation->recap_id);
        $allocation->delete();

        return response()->json(['message' => 'Alokasi budget berhasil dihapus']);
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
