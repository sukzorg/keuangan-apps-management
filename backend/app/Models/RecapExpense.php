<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RecapExpense extends Model
{
    protected $fillable = [
        'recap_id',
        'category_id',
        'name',
        'amount',
        'date',
        'payment_method_id',
        'notes',
    ];

    public function recap()
    {
        return $this->belongsTo(MonthlyRecap::class, 'recap_id');
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function paymentMethod()
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }
}
