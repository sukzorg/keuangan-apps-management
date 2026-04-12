<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    public function index()
    {
        return response()->json(
            Expense::with('category')->get()
        );
    }

    public function store(Request $request)
    {
        $request->validate([
            'category_id' => 'required|exists:categories,id',
            'name' => 'required',
            'amount' => 'required|numeric',
            'date' => 'required|date'
        ]);

        $expense = Expense::create($request->all());

        return response()->json($expense->load('category'));
    }

    public function show($id)
    {
        $expense = Expense::find($id);

        if (!$expense) {
            return response()->json(['message' => 'Date tidak ditemukan'], 404);
        }

        return response()->json($expense);
    }

    public function update(Request $request, $id)
    {
        $expense = Expense::find($id);

        if (!$expense) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $expense->update($request->all());

        return response()->json($expense);
    }

    public function destroy($id)
    {
        $expense = Expense::find($id);

        if (!$expense) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $expense->delete();

        return response()->json(['message' => 'Data berhasil dihapus']);
    }

}
