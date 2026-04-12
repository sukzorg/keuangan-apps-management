<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BusinessExpenseCategory extends Model
{
    protected $fillable = [
        'business_id',
        'name',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    // Kategori ini milik bisnis mana
    public function business()
    {
        return $this->belongsTo(BusinessProfile::class, 'business_id');
    }
}
