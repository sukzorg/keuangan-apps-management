<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DebtItem extends Model
{
    protected $fillable = [
        'debt_category_id',
        'creditor_name',
        'total_amount',
        'monthly_installment',
        'total_months',
        'remaining_months',
        'start_date',
        'due_date',
        'status',
        'notes',
    ];

    // Hutang ini masuk kategori apa (KPR, kendaraan, dll)
    public function debtCategory()
    {
        return $this->belongsTo(DebtCategory::class, 'debt_category_id');
    }

    // Riwayat pembayaran cicilan hutang ini
    public function payments()
    {
        return $this->hasMany(DebtPayment::class, 'debt_item_id');
    }

    public function recalculateProgress(): void
    {
        $paidInstallments = $this->payments()
            ->where('status', '!=', 'skipped')
            ->count();

        $remainingMonths = max($this->total_months - $paidInstallments, 0);
        $status = $remainingMonths <= 0 ? 'paid_off' : 'active';

        $this->update([
            'remaining_months' => $remainingMonths,
            'status' => $status,
        ]);
    }
}
