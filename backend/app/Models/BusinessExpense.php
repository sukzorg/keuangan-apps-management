<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BusinessExpense extends Model
{
    protected $fillable = [
        'recap_id',
        'business_id',
        'business_expense_category_id',
        'description',
        'amount',
        'expense_date',
        'payment_method_id',
        'notes',
    ];

    // Pengeluaran ini masuk ke rekap bulan mana
    public function recap()
    {
        return $this->belongsTo(MonthlyRecap::class, 'recap_id');
    }

    // Pengeluaran ini untuk bisnis mana
    public function business()
    {
        return $this->belongsTo(BusinessProfile::class, 'business_id');
    }

    // Pengeluaran ini masuk kategori apa (sparepart, transport, dll)
    public function expenseCategory()
    {
        return $this->belongsTo(BusinessExpenseCategory::class, 'business_expense_category_id');
    }

    // Dibayar via metode pembayaran apa
    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}