<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Income;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class IncomeController extends Controller
{
    public function index(Request $request)
    {
        $validated = $request->validate([
            'date_from' => 'nullable|date',
            'date_to' => 'nullable|date|after_or_equal:date_from',
        ]);

        $query = Income::with(['category', 'incomeSource'])
            ->latest('date')
            ->latest('id');

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
        // BUG FIX: Tambah validasi (sebelumnya tidak ada validasi sama sekali)
        $request->validate([
            'income_source_id' => [
                'nullable',
                Rule::exists('income_sources', 'id')->where(fn ($query) => $query->where('is_active', 1)),
            ],
            'category_id' => [
                'nullable',
                Rule::exists('categories', 'id')->where(fn ($query) => $query->where('type', 'income')),
            ],
            'name'   => 'required|string',
            'amount' => 'required|numeric',
            'date'   => 'required|date',
        ]);

        $income = Income::create($request->all());
        return response()->json($income->load(['category', 'incomeSource']), 201);
    }

    // BUG FIX: Tambah method show yang sebelumnya tidak ada
    public function show($id)
    {
        $income = Income::find($id);

        if (!$income) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        return response()->json($income->load(['category', 'incomeSource']));
    }

    public function update(Request $request, $id)
    {
        // BUG FIX: Sebelumnya 'income::find()' (lowercase) → error fatal
        $income = Income::find($id);

        if (!$income) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $request->validate([
            'income_source_id' => [
                'sometimes',
                'nullable',
                Rule::exists('income_sources', 'id')->where(fn ($query) => $query->where('is_active', 1)),
            ],
            'category_id' => [
                'sometimes',
                'nullable',
                Rule::exists('categories', 'id')->where(fn ($query) => $query->where('type', 'income')),
            ],
            'name'   => 'sometimes|string',
            'amount' => 'sometimes|numeric',
            'date'   => 'sometimes|date',
        ]);

        $income->update($request->all());

        return response()->json($income->load(['category', 'incomeSource']));
    }

    public function destroy($id)
    {
        // BUG FIX: Sebelumnya 'income::find()' (lowercase) → error fatal
        $income = Income::find($id);

        if (!$income) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $income->delete();

        return response()->json(['message' => 'Data berhasil dihapus']);
    }
}
