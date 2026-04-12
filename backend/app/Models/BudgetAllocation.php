<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BudgetAllocation extends Model
{
    protected $fillable = [
        'recap_id',
        'budget_category_id',
        'planned_amount',
        'actual_amount',
        'payment_method_id',
        'notes',
    ];

    // Alokasi ini masuk ke rekap bulan mana
    public function recap()
    {
        return $this->belongsTo(MonthlyRecap::class, 'recap_id');
    }

    // Alokasi untuk kategori budget apa (makan, transport, dll)
    public function budgetCategory()
    {
        return $this->belongsTo(BudgetCategory::class, 'budget_category_id');
    }

    // Dana ini dipindah/dibayar via apa (cash, GoPay, dll)
    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}