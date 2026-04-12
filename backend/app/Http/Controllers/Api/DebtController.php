<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\DebtItem;
use App\Models\DebtPayment;
use Illuminate\Http\Request;

class DebtController extends Controller
{
    // GET /debts — semua hutang aktif
    public function index() {
        return response()->json(
            DebtItem::with('debtCategory')
                ->orderBy('status')
                ->get()
                ->map(fn($d) => array_merge($d->toArray(), [
                    'total_paid'     => $d->payments->sum('amount_paid'),
                    'remaining_amount' => $d->total_amount - $d->payments->sum('amount_paid'),
                ]))
        );
    }

    // POST /debts — tambah hutang baru
    public function store(Request $request) {
        $request->validate([
            'debt_category_id'    => 'required|exists:debt_categories,id',
            'creditor_name'       => 'required|string',
            'total_amount'        => 'required|numeric|min:0',
            'monthly_installment' => 'required|numeric|min:0',
            'total_months'        => 'required|integer|min:1',
            'start_date'          => 'required|date',
            'due_date'            => 'required|date',
        ]);

        $debt = DebtItem::create(array_merge($request->all(), [
            'remaining_months' => $request->total_months,
            'status'           => 'active',
        ]));

        return response()->json($debt->load('debtCategory'), 201);
    }

    // POST /debts/{id}/pay — bayar cicilan bulan ini
    public function pay(Request $request, $id) {
        $debt = DebtItem::find($id);
        if (!$debt) return response()->json(['message' => 'Hutang tidak ditemukan'], 404);

        $request->validate([
            'recap_id'          => 'required|exists:monthly_recaps,id',
            'amount_paid'       => 'required|numeric|min:0',
            'payment_date'      => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'status'            => 'in:paid,partial,skipped',
        ]);

        $payment = DebtPayment::create(array_merge($request->all(), ['debt_item_id' => $id]));

        // Update sisa cicilan jika paid
        if ($request->status !== 'skipped') {
            $debt->decrement('remaining_months');
            if ($debt->remaining_months <= 0) {
                $debt->update(['status' => 'paid_off']);
            }
        }

        return response()->json($payment->load(['debtItem', 'paymentMethod']), 201);
    }
}