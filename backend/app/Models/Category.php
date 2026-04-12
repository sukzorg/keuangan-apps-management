<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    protected $fillable = ['name', 'type', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function expenses()
    {
        return $this->hasMany(Expense::class);
    }
}
