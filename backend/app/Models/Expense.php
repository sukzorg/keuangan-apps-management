<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\Category;

class Expense extends Model
{
    protected $fillable = ['category_id', 'name', 'amount', 'date'];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
