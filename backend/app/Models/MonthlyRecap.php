<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class MonthlyRecap extends Model {
    protected $fillable = ['year', 'month', 'status', 'recap_date', 'notes'];

    public function expenses()             { return $this->hasMany(RecapExpense::class, 'recap_id'); }
    public function incomeEntries()        { return $this->hasMany(IncomeEntry::class, 'recap_id'); }
    public function businessIncomeEntries(){ return $this->hasMany(BusinessIncomeEntry::class, 'recap_id'); }
    public function debtPayments()         { return $this->hasMany(DebtPayment::class, 'recap_id'); }
    public function budgetAllocations()    { return $this->hasMany(BudgetAllocation::class, 'recap_id'); }
    public function businessExpenses()     { return $this->hasMany(BusinessExpense::class, 'recap_id'); }

    // Helper: total semua income bulan ini
    public function getTotalIncomeAttribute() {
        $salary  = $this->incomeEntries->sum('amount');
        $bizInc  = $this->businessIncomeEntries->sum('amount');
        return $salary + $bizInc;
    }

    // Helper: total semua pengeluaran (debt + budget + biaya bisnis)
    public function getTotalExpenseAttribute() {
        $expense = $this->expenses->sum('amount');
        $debt    = $this->debtPayments->sum('amount_paid');
        $budget  = $this->budgetAllocations->sum('actual_amount');
        $bizExp  = $this->businessExpenses->sum('amount');
        return $expense + $debt + $budget + $bizExp;
    }

    // Helper: saldo akhir
    public function getEndingBalanceAttribute() {
        return $this->total_income - $this->total_expense;
    }
}
