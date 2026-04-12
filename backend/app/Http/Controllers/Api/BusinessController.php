<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\BusinessProfile;
use App\Models\BusinessIncomeEntry;
use App\Models\BusinessExpense;
use Illuminate\Http\Request;

class BusinessController extends Controller
{
    // GET /businesses — semua profil bisnis
    public function index() {
        return response()->json(BusinessProfile::with('expenseCategories')->where('is_active', true)->get());
    }

    // POST /businesses/{id}/income — input income bisnis
    public function addIncome(Request $request, $id) {
        $business = BusinessProfile::find($id);
        if (!$business) return response()->json(['message' => 'Bisnis tidak ditemukan'], 404);

        $request->validate([
            'recap_id'          => 'required|exists:monthly_recaps,id',
            'description'       => 'required|string',
            'amount'            => 'required|numeric|min:0',
            'received_date'     => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
        ]);

        $entry = BusinessIncomeEntry::create(array_merge($request->all(), ['business_id' => $id]));
        return response()->json($entry->load(['business', 'paymentMethod']), 201);
    }

    // POST /businesses/{id}/expense — input pengeluaran bisnis
    public function addExpense(Request $request, $id) {
        $business = BusinessProfile::find($id);
        if (!$business) return response()->json(['message' => 'Bisnis tidak ditemukan'], 404);

        $request->validate([
            'recap_id'                       => 'required|exists:monthly_recaps,id',
            'business_expense_category_id'   => 'required|exists:business_expense_categories,id',
            'description'                    => 'required|string',
            'amount'                         => 'required|numeric|min:0',
            'expense_date'                   => 'required|date',
            'payment_method_id'              => 'required|exists:payment_methods,id',
        ]);

        $expense = BusinessExpense::create(array_merge($request->all(), ['business_id' => $id]));
        return response()->json($expense->load(['business', 'expenseCategory', 'paymentMethod']), 201);
    }
}