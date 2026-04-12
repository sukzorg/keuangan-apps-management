<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Income extends Model
{
    protected $fillable = ['category_id', 'income_source_id', 'name', 'amount', 'date'];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function incomeSource()
    {
        return $this->belongsTo(IncomeSource::class);
    }
}
