<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DebtPayment extends Model
{
    protected $fillable = [
        'recap_id',
        'debt_item_id',
        'amount_paid',
        'payment_date',
        'payment_method_id',
        'status',
        'notes',
    ];

    // Pembayaran ini masuk ke rekap bulan mana
    public function recap()
    {
        return $this->belongsTo(MonthlyRecap::class, 'recap_id');
    }

    // Pembayaran untuk hutang mana
    public function debtItem()
    {
        return $this->belongsTo(DebtItem::class, 'debt_item_id');
    }

    // Dibayar via metode pembayaran apa (cash, BCA, dll)
    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}