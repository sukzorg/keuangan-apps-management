<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BusinessProfile extends Model
{
    protected $fillable = [
        'name',
        'type',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    // Satu bisnis punya banyak kategori pengeluaran
    public function expenseCategories()
    {
        return $this->hasMany(BusinessExpenseCategory::class, 'business_id');
    }

    // Satu bisnis punya banyak pengeluaran
    public function expenses()
    {
        return $this->hasMany(BusinessExpense::class, 'business_id');
    }

    // Satu bisnis punya banyak income
    public function incomeEntries()
    {
        return $this->hasMany(BusinessIncomeEntry::class, 'business_id');
    }
}
