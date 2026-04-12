<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Income;
use App\Models\Expense;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function summary()
    {
        $totalIncome = Income::sum('amount');
        $totalExpense = Expense::sum('amount');
        $balance = $totalIncome - $totalExpense;

        return response()->json([
            'total_income' => $totalIncome,
            'total_expense' => $totalExpense,
            'balance' => $balance
        ]);
    }
}
