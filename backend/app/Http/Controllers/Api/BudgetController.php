<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\BudgetAllocation;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    // POST /budget-allocations — alokasi budget untuk bulan ini
    public function store(Request $request) {
        $request->validate([
            'recap_id'           => 'required|exists:monthly_recaps,id',
            'budget_category_id' => 'required|exists:budget_categories,id',
            'planned_amount'     => 'required|numeric|min:0',
            'payment_method_id'  => 'required|exists:payment_methods,id',
            'notes'              => 'nullable|string',
        ]);

        $allocation = BudgetAllocation::create($request->all());
        return response()->json($allocation->load(['budgetCategory', 'paymentMethod']), 201);
    }

    // PUT /budget-allocations/{id}/actual — update realisasi aktual
    public function updateActual(Request $request, $id) {
        $allocation = BudgetAllocation::find($id);
        if (!$allocation) return response()->json(['message' => 'Alokasi tidak ditemukan'], 404);

        $request->validate(['actual_amount' => 'required|numeric|min:0']);
        $allocation->update(['actual_amount' => $request->actual_amount]);

        return response()->json($allocation->load(['budgetCategory', 'paymentMethod']));
    }
}