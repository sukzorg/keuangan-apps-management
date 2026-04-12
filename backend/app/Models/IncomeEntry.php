<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class IncomeEntry extends Model
{
    protected $fillable = [
        'recap_id',
        'income_source_id',
        'amount',
        'received_date',
        'payment_method_id',
        'notes',
    ];

    // Income ini masuk ke rekap bulan mana
    public function recap()
    {
        return $this->belongsTo(MonthlyRecap::class, 'recap_id');
    }

    // Income ini dari sumber mana (gaji, investasi, dll)
    public function incomeSource()
    {
        return $this->belongsTo(IncomeSource::class, 'income_source_id');
    }

    // Diterima via metode pembayaran apa
    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}