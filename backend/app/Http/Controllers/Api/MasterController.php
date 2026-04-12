<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BudgetCategory;
use App\Models\BusinessExpenseCategory;
use App\Models\BusinessProfile;
use App\Models\Category;
use App\Models\DebtCategory;
use App\Models\IncomeSource;
use App\Models\PaymentMethod;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class MasterController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $collections = [];

        foreach (array_keys($this->resourceConfigs()) as $resource) {
            $collections[$resource] = $this->buildResourceQuery($resource, $request)->get();
        }

        return response()->json([
            'message' => 'Master data berhasil dimuat.',
            'data' => $collections,
        ]);
    }

    public function list(Request $request, string $resource): JsonResponse
    {
        return response()->json(
            $this->buildResourceQuery($resource, $request)->get()
        );
    }

    public function store(Request $request, string $resource): JsonResponse
    {
        $config = $this->resolveResourceConfig($resource);
        $validated = $request->validate(
            $config['store_rules'],
            [],
            $config['attributes']
        );

        $validated = $this->filterPayloadForExistingColumns($config, $validated);

        if ($this->resourceSupportsActiveStatus($config) && ! array_key_exists('is_active', $validated)) {
            $validated['is_active'] = true;
        }

        $modelClass = $config['model'];
        $record = $modelClass::create($validated);

        return response()->json(
            $this->loadRelations($record, $config),
            201
        );
    }

    public function update(Request $request, string $resource, int $id): JsonResponse
    {
        $config = $this->resolveResourceConfig($resource);
        $validated = $request->validate(
            $config['update_rules'],
            [],
            $config['attributes']
        );
        $validated = $this->filterPayloadForExistingColumns($config, $validated);

        $record = $this->findResourceRecord($config, $id);
        $record->fill($validated);
        $record->save();

        return response()->json(
            $this->loadRelations($record->fresh(), $config)
        );
    }

    public function paymentMethods(Request $request): JsonResponse
    {
        return $this->list($request, 'payment-methods');
    }

    public function storePaymentMethod(Request $request): JsonResponse
    {
        return $this->store($request, 'payment-methods');
    }

    public function debtCategories(Request $request): JsonResponse
    {
        return $this->list($request, 'debt-categories');
    }

    public function budgetCategories(Request $request): JsonResponse
    {
        return $this->list($request, 'budget-categories');
    }

    public function incomeSources(Request $request): JsonResponse
    {
        return $this->list($request, 'income-sources');
    }

    private function buildResourceQuery(string $resource, Request $request): Builder
    {
        $config = $this->resolveResourceConfig($resource);
        $modelClass = $config['model'];
        $query = $modelClass::query();

        if (! empty($config['with'])) {
            $query->with($config['with']);
        }

        if ($this->resourceSupportsActiveStatus($config) && ! $request->boolean('include_inactive')) {
            $query->where('is_active', true);
        }

        if ($resource === 'business-expense-categories' && $request->filled('business_id')) {
            $query->where('business_id', $request->integer('business_id'));
        }

        if ($resource === 'income-sources' && $request->filled('business_id')) {
            $query->where('business_id', $request->integer('business_id'));
        }

        foreach ($config['order_by'] as $column => $direction) {
            $query->orderBy($column, $direction);
        }

        return $query;
    }

    private function loadRelations(Model $record, array $config): Model
    {
        if (! empty($config['with'])) {
            $record->load($config['with']);
        }

        return $record;
    }

    private function findResourceRecord(array $config, int $id): Model
    {
        $modelClass = $config['model'];
        $record = $modelClass::query()->find($id);

        if (! $record) {
            throw new NotFoundHttpException('Data master tidak ditemukan.');
        }

        return $record;
    }

    private function resolveResourceConfig(string $resource): array
    {
        $config = $this->resourceConfigs()[$resource] ?? null;

        if (! $config) {
            throw new NotFoundHttpException('Resource master data tidak ditemukan.');
        }

        return $config;
    }

    private function resourceSupportsActiveStatus(array $config): bool
    {
        if (! ($config['has_active'] ?? false)) {
            return false;
        }

        return Schema::hasColumn($this->modelTable($config), 'is_active');
    }

    private function filterPayloadForExistingColumns(array $config, array $payload): array
    {
        $table = $this->modelTable($config);

        return collect($payload)
            ->filter(fn ($value, $key) => Schema::hasColumn($table, $key))
            ->all();
    }

    private function modelTable(array $config): string
    {
        /** @var \Illuminate\Database\Eloquent\Model $model */
        $model = new $config['model']();

        return $model->getTable();
    }

    private function resourceConfigs(): array
    {
        return [
            'payment-methods' => [
                'model' => PaymentMethod::class,
                'has_active' => true,
                'with' => [],
                'order_by' => ['type' => 'asc', 'name' => 'asc'],
                'attributes' => [
                    'name' => 'nama metode pembayaran',
                    'type' => 'jenis metode pembayaran',
                    'account_number' => 'nomor akun',
                    'account_name' => 'nama pemilik akun',
                    'is_active' => 'status aktif',
                ],
                'store_rules' => [
                    'name' => 'required|string|max:100',
                    'type' => 'required|in:cash,e_wallet,bank_transfer',
                    'account_number' => 'nullable|string|max:100',
                    'account_name' => 'nullable|string|max:100',
                    'is_active' => 'nullable|boolean',
                ],
                'update_rules' => [
                    'name' => 'sometimes|required|string|max:100',
                    'type' => 'sometimes|required|in:cash,e_wallet,bank_transfer',
                    'account_number' => 'nullable|string|max:100',
                    'account_name' => 'nullable|string|max:100',
                    'is_active' => 'sometimes|required|boolean',
                ],
            ],
            'debt-categories' => [
                'model' => DebtCategory::class,
                'has_active' => true,
                'with' => [],
                'order_by' => ['name' => 'asc'],
                'attributes' => [
                    'name' => 'nama kategori utang',
                    'description' => 'deskripsi kategori utang',
                    'is_active' => 'status aktif',
                ],
                'store_rules' => [
                    'name' => 'required|string|max:100',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'nullable|boolean',
                ],
                'update_rules' => [
                    'name' => 'sometimes|required|string|max:100',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'sometimes|required|boolean',
                ],
            ],
            'budget-categories' => [
                'model' => BudgetCategory::class,
                'has_active' => true,
                'with' => [],
                'order_by' => ['priority' => 'asc', 'name' => 'asc'],
                'attributes' => [
                    'name' => 'nama kategori anggaran',
                    'priority' => 'prioritas anggaran',
                    'description' => 'deskripsi kategori anggaran',
                    'is_active' => 'status aktif',
                ],
                'store_rules' => [
                    'name' => 'required|string|max:100',
                    'priority' => 'required|in:wajib,penting,keinginan',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'nullable|boolean',
                ],
                'update_rules' => [
                    'name' => 'sometimes|required|string|max:100',
                    'priority' => 'sometimes|required|in:wajib,penting,keinginan',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'sometimes|required|boolean',
                ],
            ],
            'categories' => [
                'model' => Category::class,
                'has_active' => true,
                'with' => [],
                'order_by' => ['type' => 'asc', 'name' => 'asc'],
                'attributes' => [
                    'name' => 'nama kategori transaksi',
                    'type' => 'jenis kategori transaksi',
                    'is_active' => 'status aktif',
                ],
                'store_rules' => [
                    'name' => 'required|string|max:100',
                    'type' => 'required|in:income,expense',
                    'is_active' => 'nullable|boolean',
                ],
                'update_rules' => [
                    'name' => 'sometimes|required|string|max:100',
                    'type' => 'sometimes|required|in:income,expense',
                    'is_active' => 'sometimes|required|boolean',
                ],
            ],
            'income-sources' => [
                'model' => IncomeSource::class,
                'has_active' => true,
                'with' => ['business'],
                'order_by' => ['type' => 'asc', 'name' => 'asc'],
                'attributes' => [
                    'name' => 'nama sumber pemasukan',
                    'type' => 'jenis sumber pemasukan',
                    'business_id' => 'profil bisnis',
                    'description' => 'deskripsi sumber pemasukan',
                    'is_active' => 'status aktif',
                ],
                'store_rules' => [
                    'name' => 'required|string|max:100',
                    'type' => 'required|in:salary,business,investment,other',
                    'business_id' => 'nullable|exists:business_profiles,id',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'nullable|boolean',
                ],
                'update_rules' => [
                    'name' => 'sometimes|required|string|max:100',
                    'type' => 'sometimes|required|in:salary,business,investment,other',
                    'business_id' => 'nullable|exists:business_profiles,id',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'sometimes|required|boolean',
                ],
            ],
            'business-profiles' => [
                'model' => BusinessProfile::class,
                'has_active' => true,
                'with' => [],
                'order_by' => ['name' => 'asc'],
                'attributes' => [
                    'name' => 'nama profil bisnis',
                    'type' => 'jenis bisnis',
                    'description' => 'deskripsi bisnis',
                    'is_active' => 'status aktif',
                ],
                'store_rules' => [
                    'name' => 'required|string|max:100',
                    'type' => 'required|in:photography,service_gadget,internet_provider,boarding_house,app_development,other',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'nullable|boolean',
                ],
                'update_rules' => [
                    'name' => 'sometimes|required|string|max:100',
                    'type' => 'sometimes|required|in:photography,service_gadget,internet_provider,boarding_house,app_development,other',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'sometimes|required|boolean',
                ],
            ],
            'business-expense-categories' => [
                'model' => BusinessExpenseCategory::class,
                'has_active' => true,
                'with' => ['business'],
                'order_by' => ['business_id' => 'asc', 'name' => 'asc'],
                'attributes' => [
                    'business_id' => 'profil bisnis',
                    'name' => 'nama kategori pengeluaran bisnis',
                    'description' => 'deskripsi kategori pengeluaran bisnis',
                    'is_active' => 'status aktif',
                ],
                'store_rules' => [
                    'business_id' => 'required|exists:business_profiles,id',
                    'name' => 'required|string|max:100',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'nullable|boolean',
                ],
                'update_rules' => [
                    'business_id' => 'sometimes|required|exists:business_profiles,id',
                    'name' => 'sometimes|required|string|max:100',
                    'description' => 'nullable|string|max:255',
                    'is_active' => 'sometimes|required|boolean',
                ],
            ],
        ];
    }
}
