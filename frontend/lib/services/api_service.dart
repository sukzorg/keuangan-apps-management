import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/master_record.dart';

class ApiService {
  static const List<String> _baseUrls = [
    'http://192.168.2.9:8000/api',
    'http://100.76.114.56:8000/api',
  ];

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  static const Duration _probeTimeout = Duration(seconds: 4);
  static const Duration _requestTimeout = Duration(seconds: 12);

  static final http.Client _client = http.Client();
  static String? _resolvedBaseUrl;
  static Future<String>? _baseUrlResolver;

  // Income
  static Future<List<Income>> getIncomes({
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _get(
      '/incomes',
      queryParameters: {
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Income.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat income');
  }

  static Future<void> addIncome({
    required String name,
    required double amount,
    required String date,
    int? categoryId,
    int? incomeSourceId,
  }) async {
    final response = await _post(
      '/incomes',
      body: {
        'name': name,
        'amount': amount.toString(),
        'date': date,
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (incomeSourceId != null)
          'income_source_id': incomeSourceId.toString(),
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal menambah income');
    }
  }

  static Future<void> updateIncome({
    required int id,
    required String name,
    required double amount,
    required String date,
    int? categoryId,
    int? incomeSourceId,
  }) async {
    final response = await _put(
      '/incomes/$id',
      body: {
        'name': name,
        'amount': amount.toString(),
        'date': date,
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (incomeSourceId != null)
          'income_source_id': incomeSourceId.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update income');
    }
  }

  static Future<void> deleteIncome(int id) async {
    final response = await _delete('/incomes/$id');
    if (response.statusCode != 200) {
      throw Exception('Gagal hapus income');
    }
  }

  // Expense
  static Future<List<Expense>> getExpenses({
    int? recapId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final response = await _get(
      '/expenses',
      queryParameters: {
        if (recapId != null) 'recap_id': '$recapId',
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      },
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Expense.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat expenses');
  }

  static Future<bool> addExpense({
    required int categoryId,
    required String name,
    required double amount,
    required String date,
    int? recapId,
    int? paymentMethodId,
    String notes = '',
  }) async {
    final response = await _post(
      '/expenses',
      headers: _jsonHeaders,
      body: jsonEncode({
        'category_id': categoryId,
        ...?recapId == null ? null : {'recap_id': recapId},
        ...?paymentMethodId == null
            ? null
            : {'payment_method_id': paymentMethodId},
        'name': name,
        'amount': amount,
        'date': date,
        if (notes.isNotEmpty) 'notes': notes,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }

    throw Exception('Gagal menambah expense');
  }

  static Future<void> updateExpense(
    int id,
    String name,
    double amount, {
    int? categoryId,
    String? date,
    int? recapId,
    int? paymentMethodId,
    String? notes,
  }) async {
    final response = await _put(
      '/expenses/$id',
      headers: _jsonHeaders,
      body: jsonEncode({
        'name': name,
        'amount': amount,
        ...?categoryId == null ? null : {'category_id': categoryId},
        ...?date == null ? null : {'date': date},
        ...?recapId == null ? null : {'recap_id': recapId},
        ...?paymentMethodId == null
            ? null
            : {'payment_method_id': paymentMethodId},
        ...?notes == null ? null : {'notes': notes},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal update expense');
    }
  }

  static Future<void> deleteExpense(int id) async {
    final response = await _delete('/expenses/$id');
    if (response.statusCode != 200) {
      throw Exception('Gagal hapus expense');
    }
  }

  // Category
  static Future<List<Category>> getCategories({String? type}) async {
    final response = await _get(
      '/categories',
      queryParameters: type == null ? null : {'type': type},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    }

    throw Exception('Gagal memuat categories');
  }

  // Dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await _get('/dashboard');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Gagal memuat dashboard');
  }

  // Monthly recap
  static Future<List<dynamic>> getMonthlyRecaps() async {
    final response = await _get('/monthly-recaps');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat rekap bulanan');
  }

  static Future<Map<String, dynamic>> getMonthlyRecapDetail(int id) async {
    final response = await _get('/monthly-recaps/$id');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat detail rekap');
  }

  static Future<Map<String, dynamic>> createMonthlyRecap(
    int year,
    int month,
    String recapDate,
    String notes,
  ) async {
    final response = await _post(
      '/monthly-recaps',
      headers: _jsonHeaders,
      body: jsonEncode({
        'year': year,
        'month': month,
        'recap_date': recapDate,
        'notes': notes,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Gagal membuat rekap');
  }

  static Future<Map<String, dynamic>> getRecapReport({
    required int recapId,
  }) async {
    final response = await _get('/monthly-recaps/$recapId/report');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat laporan');
  }

  static Future<void> finalizeRecap(int id) async {
    final response = await _put(
      '/monthly-recaps/$id/finalize',
      headers: _jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal finalisasi rekap');
    }
  }

  // Income entries
  static Future<void> addIncomeEntry({
    required int recapId,
    required int incomeSourceId,
    required double amount,
    required String receivedDate,
    required int paymentMethodId,
    String notes = '',
  }) async {
    final response = await _post(
      '/monthly-recaps/$recapId/income-entries',
      headers: _jsonHeaders,
      body: jsonEncode({
        'income_source_id': incomeSourceId,
        'amount': amount,
        'received_date': receivedDate,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menambah income entry');
    }
  }

  static Future<Map<String, dynamic>> getIncomeEntries(int recapId) async {
    final response = await _get('/monthly-recaps/$recapId/income-entries');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat income entries');
  }

  static Future<void> updateIncomeEntry({
    required int recapId,
    required int entryId,
    required int incomeSourceId,
    required double amount,
    required String receivedDate,
    required int paymentMethodId,
    String notes = '',
  }) async {
    final response = await _put(
      '/monthly-recaps/$recapId/income-entries/$entryId',
      headers: _jsonHeaders,
      body: jsonEncode({
        'income_source_id': incomeSourceId,
        'amount': amount,
        'received_date': receivedDate,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah income entry');
    }
  }

  static Future<void> deleteIncomeEntry({
    required int recapId,
    required int entryId,
  }) async {
    final response = await _delete(
      '/monthly-recaps/$recapId/income-entries/$entryId',
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus income entry');
    }
  }

  // Business income
  static Future<void> addBusinessIncome({
    required int recapId,
    required int businessId,
    required String description,
    required double amount,
    required String receivedDate,
    required int paymentMethodId,
    String notes = '',
  }) async {
    final response = await _post(
      '/monthly-recaps/$recapId/business-incomes',
      headers: _jsonHeaders,
      body: jsonEncode({
        'business_id': businessId,
        'description': description,
        'amount': amount,
        'received_date': receivedDate,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menambah business income');
    }
  }

  static Future<void> updateBusinessIncome({
    required int recapId,
    required int entryId,
    required int businessId,
    required String description,
    required double amount,
    required String receivedDate,
    required int paymentMethodId,
    String notes = '',
  }) async {
    final response = await _put(
      '/monthly-recaps/$recapId/business-incomes/$entryId',
      headers: _jsonHeaders,
      body: jsonEncode({
        'business_id': businessId,
        'description': description,
        'amount': amount,
        'received_date': receivedDate,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah income bisnis');
    }
  }

  static Future<void> deleteBusinessIncome({
    required int recapId,
    required int entryId,
  }) async {
    final response = await _delete(
      '/monthly-recaps/$recapId/business-incomes/$entryId',
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus income bisnis');
    }
  }

  // Master data
  static Future<List<dynamic>> getPaymentMethods() async {
    final response = await _get('/payment-methods');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat payment methods');
  }

  static Future<List<dynamic>> getBusinesses() async {
    final response = await _get('/businesses');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat bisnis');
  }

  static Future<List<dynamic>> getIncomeSources() async {
    final response = await _get('/income-sources');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat income sources');
  }

  static Future<List<dynamic>> getBudgetCategories() async {
    final response = await _get('/budget-categories');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat budget categories');
  }

  static Future<List<dynamic>> getDebtCategories() async {
    final response = await _get('/debt-categories');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat debt categories');
  }

  static Future<List<MasterRecord>> getMasterData(
    String resource, {
    bool includeInactive = true,
    int? businessId,
    String? type,
  }) async {
    final query = <String, String>{
      'include_inactive': includeInactive ? '1' : '0',
    };

    if (businessId != null) {
      query['business_id'] = businessId.toString();
    }

    if (type != null) {
      query['type'] = type;
    }

    try {
      final response = await _get(
        '/master-data/$resource',
        queryParameters: query,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => MasterRecord.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback ke endpoint lama bila endpoint generik belum tersedia.
    }

    return _getLegacyMasterData(
      resource,
      includeInactive: includeInactive,
      businessId: businessId,
      type: type,
    );
  }

  static Future<MasterRecord> createMasterData(
    String resource,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _post(
        '/master-data/$resource',
        headers: _jsonHeaders,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MasterRecord.fromJson(jsonDecode(response.body));
      }

      if (resource != 'categories') {
        throw Exception(
          _extractErrorMessage(response, 'Gagal menambah master data'),
        );
      }
    } catch (_) {
      if (resource != 'categories') {
        rethrow;
      }
    }

    return _createLegacyCategory(payload);
  }

  static Future<MasterRecord> _createLegacyCategory(
    Map<String, dynamic> payload,
  ) async {
    final response = await _post(
      '/categories',
      body: {
        if (payload['name'] != null) 'name': payload['name'].toString(),
        if (payload['type'] != null) 'type': payload['type'].toString(),
        if (payload['is_active'] != null)
          'is_active': payload['is_active'] == true ? '1' : '0',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return MasterRecord.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      _extractErrorMessage(response, 'Gagal menambah master data'),
    );
  }

  static Future<MasterRecord> updateMasterData(
    String resource,
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _put(
        '/master-data/$resource/$id',
        headers: _jsonHeaders,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return MasterRecord.fromJson(jsonDecode(response.body));
      }

      if (resource != 'categories') {
        throw Exception(
          _extractErrorMessage(response, 'Gagal mengubah master data'),
        );
      }
    } catch (_) {
      if (resource != 'categories') {
        rethrow;
      }
    }

    return _updateLegacyCategory(id, payload);
  }

  static Future<MasterRecord> _updateLegacyCategory(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _post(
      '/categories/$id',
      body: {
        '_method': 'PUT',
        if (payload['name'] != null) 'name': payload['name'].toString(),
        if (payload['type'] != null) 'type': payload['type'].toString(),
        if (payload['is_active'] != null)
          'is_active': payload['is_active'] == true ? '1' : '0',
      },
    );

    if (response.statusCode == 200) {
      return MasterRecord.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      _extractErrorMessage(response, 'Gagal mengubah master data'),
    );
  }

  // Debt
  static Future<List<dynamic>> getDebts() async {
    final response = await _get('/debts');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat hutang');
  }

  static Future<void> addDebt({
    int? recapId,
    required int debtCategoryId,
    required String creditorName,
    required double totalAmount,
    required double monthlyInstallment,
    required int totalMonths,
    required String startDate,
    required String dueDate,
    String notes = '',
  }) async {
    final response = await _post(
      '/debts',
      headers: _jsonHeaders,
      body: jsonEncode({
        ...?recapId == null ? null : {'recap_id': recapId},
        'debt_category_id': debtCategoryId,
        'creditor_name': creditorName,
        'total_amount': totalAmount,
        'monthly_installment': monthlyInstallment,
        'total_months': totalMonths,
        'start_date': startDate,
        'due_date': dueDate,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menambah hutang');
    }
  }

  static Future<void> updateDebt({
    required int id,
    required int debtCategoryId,
    required String creditorName,
    required double totalAmount,
    required double monthlyInstallment,
    required int totalMonths,
    required String startDate,
    required String dueDate,
    String notes = '',
  }) async {
    final response = await _put(
      '/debts/$id',
      headers: _jsonHeaders,
      body: jsonEncode({
        'debt_category_id': debtCategoryId,
        'creditor_name': creditorName,
        'total_amount': totalAmount,
        'monthly_installment': monthlyInstallment,
        'total_months': totalMonths,
        'start_date': startDate,
        'due_date': dueDate,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah hutang');
    }
  }

  static Future<void> deleteDebt(int id) async {
    final response = await _delete('/debts/$id');
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus hutang');
    }
  }

  static Future<void> payDebt({
    required int debtId,
    required int recapId,
    required double amountPaid,
    required String paymentDate,
    required int paymentMethodId,
    String status = 'paid',
    String notes = '',
  }) async {
    final response = await _post(
      '/debts/$debtId/pay',
      headers: _jsonHeaders,
      body: jsonEncode({
        'recap_id': recapId,
        'amount_paid': amountPaid,
        'payment_date': paymentDate,
        'payment_method_id': paymentMethodId,
        'status': status,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal membayar cicilan');
    }
  }

  static Future<void> updateDebtPayment({
    required int recapId,
    required int paymentId,
    required double amountPaid,
    required String paymentDate,
    required int paymentMethodId,
    String status = 'paid',
    String notes = '',
  }) async {
    final response = await _put(
      '/monthly-recaps/$recapId/debt-payments/$paymentId',
      headers: _jsonHeaders,
      body: jsonEncode({
        'amount_paid': amountPaid,
        'payment_date': paymentDate,
        'payment_method_id': paymentMethodId,
        'status': status,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah pembayaran hutang');
    }
  }

  static Future<void> deleteDebtPayment({
    required int recapId,
    required int paymentId,
  }) async {
    final response = await _delete(
      '/monthly-recaps/$recapId/debt-payments/$paymentId',
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus pembayaran hutang');
    }
  }

  // Budget allocation
  static Future<void> addBudgetAllocation({
    required int recapId,
    required int budgetCategoryId,
    required double plannedAmount,
    required int paymentMethodId,
    String notes = '',
  }) async {
    final response = await _post(
      '/budget-allocations',
      headers: _jsonHeaders,
      body: jsonEncode({
        'recap_id': recapId,
        'budget_category_id': budgetCategoryId,
        'planned_amount': plannedAmount,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menambah alokasi budget');
    }
  }

  static Future<void> updateBudgetAllocation({
    required int id,
    required int budgetCategoryId,
    required double plannedAmount,
    required int paymentMethodId,
    double? actualAmount,
    String notes = '',
  }) async {
    final response = await _put(
      '/budget-allocations/$id',
      headers: _jsonHeaders,
      body: jsonEncode({
        'budget_category_id': budgetCategoryId,
        'planned_amount': plannedAmount,
        'payment_method_id': paymentMethodId,
        ...?actualAmount == null ? null : {'actual_amount': actualAmount},
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah alokasi budget');
    }
  }

  static Future<void> deleteBudgetAllocation(int id) async {
    final response = await _delete('/budget-allocations/$id');
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus alokasi budget');
    }
  }

  // Business expense
  static Future<void> addBusinessExpense({
    required int businessId,
    required int recapId,
    required int businessExpenseCategoryId,
    required String description,
    required double amount,
    required String expenseDate,
    required int paymentMethodId,
    String notes = '',
  }) async {
    final response = await _post(
      '/businesses/$businessId/expense',
      headers: _jsonHeaders,
      body: jsonEncode({
        'recap_id': recapId,
        'business_expense_category_id': businessExpenseCategoryId,
        'description': description,
        'amount': amount,
        'expense_date': expenseDate,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menambah pengeluaran bisnis');
    }
  }

  static Future<void> updateBusinessExpense({
    required int businessId,
    required int expenseId,
    required int businessExpenseCategoryId,
    required String description,
    required double amount,
    required String expenseDate,
    required int paymentMethodId,
    String notes = '',
  }) async {
    final response = await _put(
      '/businesses/$businessId/expense/$expenseId',
      headers: _jsonHeaders,
      body: jsonEncode({
        'business_expense_category_id': businessExpenseCategoryId,
        'description': description,
        'amount': amount,
        'expense_date': expenseDate,
        'payment_method_id': paymentMethodId,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah pengeluaran bisnis');
    }
  }

  static Future<void> deleteBusinessExpense({
    required int businessId,
    required int expenseId,
  }) async {
    final response = await _delete(
      '/businesses/$businessId/expense/$expenseId',
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus pengeluaran bisnis');
    }
  }

  static String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final dynamic body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['message'] != null) {
          return body['message'].toString();
        }

        if (body['errors'] is Map<String, dynamic>) {
          final errors = body['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }
      }
    } catch (_) {
      // Gunakan fallback bila body error tidak bisa diparsing.
    }

    return fallback;
  }

  static Future<List<MasterRecord>> _getLegacyMasterData(
    String resource, {
    required bool includeInactive,
    int? businessId,
    String? type,
  }) async {
    late final List<dynamic> rawData;

    switch (resource) {
      case 'payment-methods':
        rawData = await getPaymentMethods();
        break;
      case 'debt-categories':
        rawData = await getDebtCategories();
        break;
      case 'budget-categories':
        rawData = await getBudgetCategories();
        break;
      case 'categories':
        rawData = await getCategories(type: type);
        break;
      case 'income-sources':
        rawData = await getIncomeSources();
        break;
      case 'business-profiles':
        rawData = await getBusinesses();
        break;
      case 'business-expense-categories':
        final businesses = await getBusinesses();
        rawData = businesses
            .where(
              (business) => businessId == null || business['id'] == businessId,
            )
            .expand((business) {
              final categories =
                  (business['expense_categories'] as List<dynamic>? ??
                  const []);
              return categories.map(
                (category) => {
                  ...Map<String, dynamic>.from(category as Map),
                  'business': {'id': business['id'], 'name': business['name']},
                },
              );
            })
            .toList();
        break;
      default:
        throw Exception('Gagal memuat master data $resource');
    }

    final records = rawData
        .map((item) => MasterRecord.fromJson(_normalizeMasterItem(item)))
        .toList();

    if (includeInactive) {
      return records;
    }

    return records.where((record) => record.isActive).toList();
  }

  static Map<String, dynamic> _normalizeMasterItem(dynamic item) {
    if (item is MasterRecord) {
      return item.raw;
    }

    if (item is Category) {
      return item.toJson();
    }

    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }

    throw Exception('Format master data tidak dikenali');
  }

  static Future<String> _resolveBaseUrl({bool forceRefresh = false}) async {
    if (!forceRefresh && _resolvedBaseUrl != null) {
      return _resolvedBaseUrl!;
    }

    if (!forceRefresh && _baseUrlResolver != null) {
      return _baseUrlResolver!;
    }

    final resolver = _findReachableBaseUrl();
    if (!forceRefresh) {
      _baseUrlResolver = resolver;
    }

    try {
      final resolvedBaseUrl = await resolver;
      _resolvedBaseUrl = resolvedBaseUrl;
      return resolvedBaseUrl;
    } finally {
      if (!forceRefresh && identical(_baseUrlResolver, resolver)) {
        _baseUrlResolver = null;
      }
    }
  }

  static Future<String> _findReachableBaseUrl() async {
    final resolvedBaseUrl = _resolvedBaseUrl;
    final candidates = <String>[
      ...[resolvedBaseUrl].whereType<String>(),
      ..._baseUrls.where((url) => url != resolvedBaseUrl),
    ];

    Object? lastError;

    for (final baseUrl in candidates) {
      try {
        final response = await _client
            .get(_buildUri(baseUrl, '/payment-methods'))
            .timeout(_probeTimeout);

        final contentType = response.headers['content-type'] ?? '';
        final looksLikeJson =
            contentType.contains('application/json') ||
            response.body.trim().startsWith('[') ||
            response.body.trim().startsWith('{');

        if (response.statusCode == 200 && looksLikeJson) {
          return baseUrl;
        }

        lastError = Exception(
          'Server merespons status ${response.statusCode} pada $baseUrl',
        );
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'Tidak dapat terhubung ke server lokal maupun Tailscale. '
      'Pastikan salah satu endpoint aktif. Detail: $lastError',
    );
  }

  static Uri _buildUri(
    String baseUrl,
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters?.isEmpty ?? true
          ? null
          : queryParameters,
    );
  }

  static bool _isConnectionError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException;
  }

  static Future<http.Response> _request(
    Future<http.Response> Function(String baseUrl) perform,
  ) async {
    final primaryBaseUrl = await _resolveBaseUrl();

    try {
      return await perform(primaryBaseUrl).timeout(_requestTimeout);
    } catch (error) {
      if (!_isConnectionError(error)) {
        rethrow;
      }

      _resolvedBaseUrl = null;
      final fallbackBaseUrl = await _resolveBaseUrl(forceRefresh: true);
      if (fallbackBaseUrl == primaryBaseUrl) {
        rethrow;
      }

      return perform(fallbackBaseUrl).timeout(_requestTimeout);
    }
  }

  static Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _request(
      (baseUrl) => _client.get(
        _buildUri(baseUrl, path, queryParameters: queryParameters),
      ),
    );
  }

  static Future<http.Response> _post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      (baseUrl) => _client.post(
        _buildUri(baseUrl, path, queryParameters: queryParameters),
        headers: headers,
        body: body,
        encoding: encoding,
      ),
    );
  }

  static Future<http.Response> _put(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      (baseUrl) => _client.put(
        _buildUri(baseUrl, path, queryParameters: queryParameters),
        headers: headers,
        body: body,
        encoding: encoding,
      ),
    );
  }

  static Future<http.Response> _delete(
    String path, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      (baseUrl) => _client.delete(
        _buildUri(baseUrl, path, queryParameters: queryParameters),
        headers: headers,
        body: body,
        encoding: encoding,
      ),
    );
  }
}
