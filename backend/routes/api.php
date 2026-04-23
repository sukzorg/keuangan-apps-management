<?php

use Illuminate\Support\Facades\Route;

// ── Controllers lama (tetap ada) ─────────────────────────────────────
use App\Http\Controllers\Api\IncomeController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DashboardController;

// ── Controllers baru ─────────────────────────────────────────────────
use App\Http\Controllers\Api\MonthlyRecapController;
use App\Http\Controllers\Api\DebtController;
use App\Http\Controllers\Api\BusinessController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\MasterController;

// ════════════════════════════════════════════════════════════════════
// MASTER DATA
// ════════════════════════════════════════════════════════════════════
Route::get('/master-data',              [MasterController::class, 'index']);
Route::get('/master-data/{resource}',   [MasterController::class, 'list']);
Route::post('/master-data/{resource}',  [MasterController::class, 'store']);
Route::put('/master-data/{resource}/{id}', [MasterController::class, 'update']);

Route::get('/payment-methods',          [MasterController::class, 'paymentMethods']);
Route::post('/payment-methods',         [MasterController::class, 'storePaymentMethod']);
Route::get('/debt-categories',          [MasterController::class, 'debtCategories']);
Route::get('/budget-categories',        [MasterController::class, 'budgetCategories']);
Route::get('/categories',               [CategoryController::class, 'index']);
Route::post('/categories',              [CategoryController::class, 'store']);
Route::put('/categories/{id}',          [CategoryController::class, 'update']);
Route::get('/income-sources',           [MasterController::class, 'incomeSources']);

// ════════════════════════════════════════════════════════════════════
// BISNIS
// ════════════════════════════════════════════════════════════════════
Route::get('/businesses',                      [BusinessController::class, 'index']);
Route::post('/businesses/{id}/income',         [BusinessController::class, 'addIncome']);
Route::post('/businesses/{id}/expense',        [BusinessController::class, 'addExpense']);
Route::put('/businesses/{id}/expense/{expenseId}', [BusinessController::class, 'updateExpense']);
Route::delete('/businesses/{id}/expense/{expenseId}', [BusinessController::class, 'deleteExpense']);

// ════════════════════════════════════════════════════════════════════
// MONTHLY RECAP (inti aplikasi)
// ════════════════════════════════════════════════════════════════════
Route::get('/monthly-recaps',                               [MonthlyRecapController::class, 'index']);
Route::post('/monthly-recaps',                              [MonthlyRecapController::class, 'store']);
Route::get('/monthly-recaps/{id}',                          [MonthlyRecapController::class, 'show']);
Route::put('/monthly-recaps/{id}/finalize',                 [MonthlyRecapController::class, 'finalize']);
Route::get('/monthly-recaps/{id}/report',                   [MonthlyRecapController::class, 'report']);
Route::post('/monthly-recaps/{id}/expenses',                [MonthlyRecapController::class, 'addExpense']);
Route::get('/monthly-recaps/{id}/expenses',                 [MonthlyRecapController::class, 'listExpenses']);
Route::put('/monthly-recaps/{id}/expenses/{expenseId}',     [MonthlyRecapController::class, 'updateExpense']);
Route::delete('/monthly-recaps/{id}/expenses/{expenseId}',  [MonthlyRecapController::class, 'deleteExpense']);

// Income entries dalam satu rekap (gaji, investasi, dll)
Route::post('/monthly-recaps/{id}/income-entries',          [MonthlyRecapController::class, 'addIncomeEntry']);
Route::get('/monthly-recaps/{id}/income-entries',           [MonthlyRecapController::class, 'listIncomeEntries']);
Route::put('/monthly-recaps/{id}/income-entries/{entryId}', [MonthlyRecapController::class, 'updateIncomeEntry']);
Route::delete('/monthly-recaps/{id}/income-entries/{entryId}', [MonthlyRecapController::class, 'deleteIncomeEntry']);

// Business income entries dalam satu rekap
Route::post('/monthly-recaps/{id}/business-incomes',        [MonthlyRecapController::class, 'addBusinessIncome']);
Route::get('/monthly-recaps/{id}/business-incomes',         [MonthlyRecapController::class, 'listBusinessIncomes']);
Route::put('/monthly-recaps/{id}/business-incomes/{entryId}', [MonthlyRecapController::class, 'updateBusinessIncome']);
Route::delete('/monthly-recaps/{id}/business-incomes/{entryId}', [MonthlyRecapController::class, 'deleteBusinessIncome']);
Route::put('/monthly-recaps/{id}/debt-payments/{paymentId}', [MonthlyRecapController::class, 'updateDebtPayment']);
Route::delete('/monthly-recaps/{id}/debt-payments/{paymentId}', [MonthlyRecapController::class, 'deleteDebtPayment']);

// ════════════════════════════════════════════════════════════════════
// HUTANG (DEBT)
// ════════════════════════════════════════════════════════════════════
Route::get('/debts',                [DebtController::class, 'index']);
Route::post('/debts',               [DebtController::class, 'store']);
Route::put('/debts/{id}',           [DebtController::class, 'update']);
Route::delete('/debts/{id}',        [DebtController::class, 'destroy']);
Route::post('/debts/{id}/pay',      [DebtController::class, 'pay']);

// ════════════════════════════════════════════════════════════════════
// BUDGET ALOKASI
// ════════════════════════════════════════════════════════════════════
Route::post('/budget-allocations',                          [BudgetController::class, 'store']);
Route::put('/budget-allocations/{id}',                      [BudgetController::class, 'update']);
Route::delete('/budget-allocations/{id}',                   [BudgetController::class, 'destroy']);
Route::put('/budget-allocations/{id}/actual',               [BudgetController::class, 'updateActual']);

// ════════════════════════════════════════════════════════════════════
// INCOME & EXPENSE (lama - tetap dipertahankan)
// ════════════════════════════════════════════════════════════════════
Route::get('/incomes',              [IncomeController::class, 'index']);
Route::post('/incomes',             [IncomeController::class, 'store']);
Route::get('/incomes/{id}',         [IncomeController::class, 'show']);
Route::put('/incomes/{id}',         [IncomeController::class, 'update']);
Route::delete('/incomes/{id}',      [IncomeController::class, 'destroy']);

Route::get('/expenses',             [ExpenseController::class, 'index']);
Route::post('/expenses',            [ExpenseController::class, 'store']);
Route::get('/expenses/{id}',        [ExpenseController::class, 'show']);
Route::put('/expenses/{id}',        [ExpenseController::class, 'update']);
Route::delete('/expenses/{id}',     [ExpenseController::class, 'destroy']);

// ════════════════════════════════════════════════════════════════════
// DASHBOARD (lama - tetap)
// ════════════════════════════════════════════════════════════════════
Route::get('/dashboard',            [DashboardController::class, 'summary']);
