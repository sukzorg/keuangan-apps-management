<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class IncomeSource extends Model
{
    protected $fillable = [
        'name',
        'type',
        'business_id',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    // Jika type = business, ini link ke bisnis mana
    public function business()
    {
        return $this->belongsTo(BusinessProfile::class, 'business_id');
    }
}
