<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $query = Category::query();

        if (Schema::hasColumn('categories', 'is_active')) {
            $query->where('is_active', true);
        }

        if ($request->filled('type')) {
            $query->where('type', $request->string('type')->toString());
        }

        return response()->json($query->orderBy('type')->orderBy('name')->get());
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'type' => 'required|in:income,expense',
            'is_active' => 'nullable|boolean',
        ]);

        $payload = [
            'name' => $request->input('name'),
            'type' => $request->input('type'),
        ];

        if (Schema::hasColumn('categories', 'is_active')) {
            $payload['is_active'] = $request->boolean('is_active', true);
        }

        $category = Category::create($payload);

        return response()->json($category);
    }

    public function update(Request $request, $id)
    {
        $category = Category::find($id);

        if (! $category) {
            return response()->json(['message' => 'Data tidak ditemukan'], 404);
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:100',
            'type' => 'sometimes|required|in:income,expense',
            'is_active' => 'nullable|boolean',
        ]);

        $payload = collect([
            'name' => $request->input('name'),
            'type' => $request->input('type'),
        ])->filter(fn ($value) => $value !== null)->all();

        if (Schema::hasColumn('categories', 'is_active') && $request->has('is_active')) {
            $payload['is_active'] = $request->boolean('is_active');
        }

        $category->update($payload);

        return response()->json($category);
    }
}
