<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BusinessIncomeEntry extends Model
{
    protected $fillable = [
        'recap_id',
        'business_id',
        'description',
        'amount',
        'received_date',
        'payment_method_id',
        'notes',
    ];

    // Income bisnis ini masuk ke rekap bulan mana
    public function recap()
    {
        return $this->belongsTo(MonthlyRecap::class, 'recap_id');
    }

    // Income ini dari bisnis mana (photography, service HP, dll)
    public function business()
    {
        return $this->belongsTo(BusinessProfile::class, 'business_id');
    }

    // Diterima via metode pembayaran apa
    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}