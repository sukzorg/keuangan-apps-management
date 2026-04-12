<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BudgetCategory extends Model
{
    protected $fillable = [
        'name',
        'priority',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
