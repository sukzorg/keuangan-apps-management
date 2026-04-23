<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DebtItem;
use App\Models\MonthlyRecap;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;

class DebtController extends Controller
{
    public function index()
    {
        return response()->json(
            DebtItem::with(['debtCategory', 'payments'])
                ->orderBy('status')
                ->orderByDesc('id')
                ->get()
                ->map(fn ($debt) => array_merge($debt->toArray(), [
                    'total_paid' => $debt->payments->sum('amount_paid'),
                    'remaining_amount' => $debt->total_amount - $debt->payments->sum('amount_paid'),
                ]))
        );
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'recap_id' => 'nullable|exists:monthly_recaps,id',
            'debt_category_id' => 'required|exists:debt_categories,id',
            'creditor_name' => 'required|string|max:255',
            'total_amount' => 'required|numeric|min:0',
            'monthly_installment' => 'required|numeric|min:0',
            'total_months' => 'required|integer|min:1',
            'start_date' => 'required|date',
            'due_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        if (!empty($validated['recap_id'])) {
            $this->ensureRecapEditable((int) $validated['recap_id']);
        }

        unset($validated['recap_id']);

        $debt = DebtItem::create(array_merge($validated, [
            'remaining_months' => $validated['total_months'],
            'status' => 'active',
        ]));

        return response()->json($debt->load('debtCategory'), 201);
    }

    public function update(Request $request, $id)
    {
        $debt = DebtItem::with('payments.recap')->find($id);
        if (!$debt) {
            return response()->json(['message' => 'Hutang tidak ditemukan'], 404);
        }

        $this->ensureDebtEditable($debt);

        $validated = $request->validate([
            'debt_category_id' => 'sometimes|exists:debt_categories,id',
            'creditor_name' => 'sometimes|string|max:255',
            'total_amount' => 'sometimes|numeric|min:0',
            'monthly_installment' => 'sometimes|numeric|min:0',
            'total_months' => 'sometimes|integer|min:1',
            'start_date' => 'sometimes|date',
            'due_date' => 'sometimes|date',
            'notes' => 'sometimes|nullable|string',
        ]);

        $debt->update($validated);
        $debt->refresh();
        $debt->recalculateProgress();

        return response()->json($debt->load('debtCategory'));
    }

    public function destroy($id)
    {
        $debt = DebtItem::with('payments.recap')->find($id);
        if (!$debt) {
            return response()->json(['message' => 'Hutang tidak ditemukan'], 404);
        }

        $this->ensureDebtEditable($debt);

        $debt->payments()->delete();
        $debt->delete();

        return response()->json(['message' => 'Hutang berhasil dihapus']);
    }

    public function pay(Request $request, $id)
    {
        $debt = DebtItem::find($id);
        if (!$debt) {
            return response()->json(['message' => 'Hutang tidak ditemukan'], 404);
        }

        $validated = $request->validate([
            'recap_id' => 'required|exists:monthly_recaps,id',
            'amount_paid' => 'required|numeric|min:0',
            'payment_date' => 'required|date',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'status' => 'nullable|in:paid,partial,skipped',
            'notes' => 'nullable|string',
        ]);

        $this->ensureRecapEditable((int) $validated['recap_id']);

        $payment = $debt->payments()->create(array_merge($validated, [
            'status' => $validated['status'] ?? 'paid',
        ]));

        $debt->refresh();
        $debt->recalculateProgress();

        return response()->json($payment->load(['debtItem', 'paymentMethod']), 201);
    }

    private function ensureRecapEditable(int $recapId): void
    {
        $recap = MonthlyRecap::find($recapId);

        if ($recap && in_array($recap->status, ['final', 'finalized'], true)) {
            throw new HttpResponseException(response()->json([
                'message' => 'Rekap yang sudah difinalisasi tidak dapat diubah.',
            ], 422));
        }
    }

    private function ensureDebtEditable(DebtItem $debt): void
    {
        $hasFinalizedPayments = $debt->payments
            ->contains(fn ($payment) => in_array(optional($payment->recap)->status, ['final', 'finalized'], true));

        if ($hasFinalizedPayments) {
            throw new HttpResponseException(response()->json([
                'message' => 'Hutang yang sudah tercatat pada rekap final tidak dapat diubah atau dihapus.',
            ], 422));
        }
    }
}
