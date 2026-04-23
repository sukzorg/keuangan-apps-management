import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/master_record.dart';
import '../../services/api_service.dart';
import 'recap_report_page.dart';

class RecapDetailPage extends StatefulWidget {
  final int recapId;
  final String title;

  const RecapDetailPage({
    super.key,
    required this.recapId,
    required this.title,
  });

  @override
  State<RecapDetailPage> createState() => _RecapDetailPageState();
}

class _RecapDetailPageState extends State<RecapDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _report;

  List<dynamic> _incomeSources = [];
  List<dynamic> _paymentMethods = [];
  List<dynamic> _businesses = [];
  List<dynamic> _debtCategories = [];
  List<dynamic> _budgetCategories = [];
  List<dynamic> _debtItems = [];
  List<dynamic> _expenseCategories = [];
  bool _masterLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReport();
    _loadMasterData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReport() {
    setState(() {
      _report = ApiService.getRecapReport(recapId: widget.recapId);
    });
  }

  Future<void> _refreshData({bool reloadMaster = false}) async {
    if (reloadMaster) {
      await _loadMasterData();
    }
    _loadReport();
  }

  Future<void> _loadMasterData() async {
    try {
      final results = await Future.wait([
        ApiService.getIncomeSources(),
        ApiService.getPaymentMethods(),
        ApiService.getBusinesses(),
        ApiService.getDebtCategories(),
        ApiService.getBudgetCategories(),
        ApiService.getDebts(),
        ApiService.getCategories(type: 'expense'),
      ]);

      setState(() {
        _incomeSources = results[0];
        _paymentMethods = results[1];
        _businesses = results[2];
        _debtCategories = results[3];
        _budgetCategories = results[4];
        _debtItems = results[5];
        _expenseCategories = results[6];
        _masterLoaded = true;
      });
    } catch (error) {
      debugPrint('Error load master: $error');
      _showError('Gagal memuat master data: $error');
    }
  }

  Map<String, dynamic> _normalizeItem(dynamic item) {
    if (item is Category) {
      return item.toJson();
    }

    if (item is MasterRecord) {
      return item.raw;
    }

    if (item is Map<String, dynamic>) {
      return item;
    }

    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }

    throw Exception('Format data tidak dikenali: ${item.runtimeType}');
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic raw) {
    return (raw as List? ?? const [])
        .map(_normalizeItem)
        .toList();
  }

  List<Map<String, dynamic>> _businessExpenseCategoriesFor(int? businessId) {
    if (businessId == null) {
      return const [];
    }

    final business = _businesses
        .map(_normalizeItem)
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) => item?['id'] == businessId,
          orElse: () => null,
        );

    if (business == null) {
      return const [];
    }

    return _listOfMaps(business['expense_categories']);
  }

  String _currentDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
    StateSetter setModalState,
  ) async {
    final initial = _tryParseDate(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');

    setModalState(() {
      controller.text = '${picked.year}-$month-$day';
    });
  }

  DateTime? _tryParseDate(String value) {
    if (value.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  double? _parseAmount(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    return double.tryParse(normalized);
  }

  String _formatRupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    if (number >= 1000000) {
      return 'Rp ${(number / 1000000).toStringAsFixed(1)} Jt';
    }
    if (number >= 1000) {
      return 'Rp ${(number / 1000).toStringAsFixed(0)} Rb';
    }
    return 'Rp ${number.toStringAsFixed(0)}';
  }

  String _formatDateLabel(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final date = _tryParseDate(value);
    if (date == null) {
      return value;
    }

    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${monthNames[date.month]} ${date.year}';
  }

  bool _isFinalized(Map<String, dynamic> report) {
    final status = report['status']?.toString();
    return status == 'final' || status == 'finalized';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<bool> _confirmDelete(String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus $label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  Future<void> _executeDelete(
    String label,
    Future<void> Function() action, {
    bool reloadMaster = false,
  }) async {
    final confirmed = await _confirmDelete(label);
    if (!confirmed) {
      return;
    }

    try {
      await action();
      await _refreshData(reloadMaster: reloadMaster);
      if (!mounted) {
        return;
      }
      _showSuccess('$label berhasil dihapus');
    } catch (error) {
      _showError('Gagal menghapus data: $error');
    }
  }

  Future<void> _showFormSheet({
    required String title,
    required String saveLabel,
    required Color color,
    required Widget Function(StateSetter setModalState) contentBuilder,
    required Future<void> Function() onSave,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var isSaving = false;

        return StatefulBuilder(
          builder: (sheetContext, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  contentBuilder(setModalState),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              try {
                                await onSave();
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (error) {
                                _showError('Gagal menyimpan data: $error');
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(saveLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dropdownField({
    required String label,
    required List<dynamic> items,
    required int? value,
    required ValueChanged<int?> onChanged,
    String Function(dynamic item)? labelBuilder,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        final itemMap = _normalizeItem(item);
        final itemLabel =
            labelBuilder?.call(itemMap) ?? (itemMap['name']?.toString() ?? '-');
        return DropdownMenuItem<int>(
          value: itemMap['id'] as int,
          child: Text(
            itemLabel,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dateField(
    TextEditingController controller,
    String label,
    StateSetter setModalState,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _pickDate(context, controller, setModalState),
        ),
      ),
      onTap: () => _pickDate(context, controller, setModalState),
    );
  }

  bool _ensureRequired(
    List<bool> checks,
    String message,
  ) {
    final valid = checks.every((item) => item);
    if (!valid) {
      _showError(message);
    }
    return valid;
  }

  void _showIncomeEntryDialog({
    Map<String, dynamic>? existing,
  }) {
    if (!_masterLoaded) {
      return;
    }

    int? selectedSourceId = existing?['income_source']?['id'] as int?;
    int? selectedMethodId = existing?['payment_method']?['id'] as int?;
    final amountController = TextEditingController(
      text: existing?['amount']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: existing?['received_date']?.toString() ?? _currentDate(),
    );
    final notesController = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    final isEdit = existing != null;

    _showFormSheet(
      title: isEdit ? 'Edit Pemasukan' : 'Tambah Pemasukan',
      saveLabel: isEdit ? 'Simpan Perubahan' : 'Simpan Pemasukan',
      color: Colors.green,
      contentBuilder: (setModalState) => Column(
        children: [
          _dropdownField(
            label: 'Sumber Pemasukan',
            items: _incomeSources,
            value: selectedSourceId,
            onChanged: (value) => setModalState(() => selectedSourceId = value),
          ),
          const SizedBox(height: 12),
          _textField(amountController, 'Jumlah (Rp)', isNumber: true),
          const SizedBox(height: 12),
          _dateField(dateController, 'Tanggal Diterima', setModalState),
          const SizedBox(height: 12),
          _dropdownField(
            label: 'Metode Pembayaran',
            items: _paymentMethods,
            value: selectedMethodId,
            onChanged: (value) => setModalState(() => selectedMethodId = value),
          ),
          const SizedBox(height: 12),
          _textField(notesController, 'Catatan', maxLines: 2),
        ],
      ),
      onSave: () async {
        final amount = _parseAmount(amountController.text);
        final valid = _ensureRequired(
          [
            selectedSourceId != null,
            selectedMethodId != null,
            amount != null && amount > 0,
            dateController.text.isNotEmpty,
          ],
          'Lengkapi semua field pemasukan dengan benar.',
        );
        if (!valid) {
          return;
        }

        if (isEdit) {
          await ApiService.updateIncomeEntry(
            recapId: widget.recapId,
            entryId: existing['id'] as int,
            incomeSourceId: selectedSourceId!,
            amount: amount!,
            receivedDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        } else {
          await ApiService.addIncomeEntry(
            recapId: widget.recapId,
            incomeSourceId: selectedSourceId!,
            amount: amount!,
            receivedDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        }

        await _refreshData();
        if (!mounted) {
          return;
        }
        _showSuccess(
          isEdit
              ? 'Pemasukan berhasil diperbarui'
              : 'Pemasukan berhasil ditambahkan',
        );
      },
    );
  }

  void _showBusinessIncomeDialog({
    Map<String, dynamic>? existing,
  }) {
    if (!_masterLoaded) {
      return;
    }

    int? selectedBusinessId = existing?['business']?['id'] as int?;
    int? selectedMethodId = existing?['payment_method']?['id'] as int?;
    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: existing?['amount']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: existing?['received_date']?.toString() ?? _currentDate(),
    );
    final notesController = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    final isEdit = existing != null;

    _showFormSheet(
      title: isEdit ? 'Edit Income Bisnis' : 'Tambah Income Bisnis',
      saveLabel: isEdit ? 'Simpan Perubahan' : 'Simpan Income Bisnis',
      color: Colors.blue,
      contentBuilder: (setModalState) => Column(
        children: [
          _dropdownField(
            label: 'Bisnis',
            items: _businesses,
            value: selectedBusinessId,
            onChanged: (value) => setModalState(() => selectedBusinessId = value),
          ),
          const SizedBox(height: 12),
          _textField(
            descriptionController,
            'Deskripsi',
            hint: 'contoh: Foto wedding Bandung',
          ),
          const SizedBox(height: 12),
          _textField(amountController, 'Jumlah (Rp)', isNumber: true),
          const SizedBox(height: 12),
          _dateField(dateController, 'Tanggal Diterima', setModalState),
          const SizedBox(height: 12),
          _dropdownField(
            label: 'Metode Pembayaran',
            items: _paymentMethods,
            value: selectedMethodId,
            onChanged: (value) => setModalState(() => selectedMethodId = value),
          ),
          const SizedBox(height: 12),
          _textField(notesController, 'Catatan', maxLines: 2),
        ],
      ),
      onSave: () async {
        final amount = _parseAmount(amountController.text);
        final valid = _ensureRequired(
          [
            selectedBusinessId != null,
            selectedMethodId != null,
            descriptionController.text.trim().isNotEmpty,
            amount != null && amount > 0,
            dateController.text.isNotEmpty,
          ],
          'Lengkapi semua field income bisnis dengan benar.',
        );
        if (!valid) {
          return;
        }

        if (isEdit) {
          await ApiService.updateBusinessIncome(
            recapId: widget.recapId,
            entryId: existing['id'] as int,
            businessId: selectedBusinessId!,
            description: descriptionController.text.trim(),
            amount: amount!,
            receivedDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        } else {
          await ApiService.addBusinessIncome(
            recapId: widget.recapId,
            businessId: selectedBusinessId!,
            description: descriptionController.text.trim(),
            amount: amount!,
            receivedDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        }

        await _refreshData();
        if (!mounted) {
          return;
        }
        _showSuccess(
          isEdit
              ? 'Income bisnis berhasil diperbarui'
              : 'Income bisnis berhasil ditambahkan',
        );
      },
    );
  }

  void _showExpenseDialog({
    Map<String, dynamic>? existing,
  }) {
    if (!_masterLoaded) {
      return;
    }

    int? selectedCategoryId = existing?['category']?['id'] as int?;
    int? selectedMethodId = existing?['payment_method']?['id'] as int?;
    final nameController = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: existing?['amount']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: existing?['date']?.toString() ?? _currentDate(),
    );
    final notesController = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    final isEdit = existing != null;

    _showFormSheet(
      title: isEdit ? 'Edit Pengeluaran Bulanan' : 'Tambah Pengeluaran Bulanan',
      saveLabel: isEdit ? 'Simpan Perubahan' : 'Simpan Pengeluaran',
      color: Colors.red,
      contentBuilder: (setModalState) => Column(
        children: [
          _dropdownField(
            label: 'Kategori Pengeluaran',
            items: _expenseCategories,
            value: selectedCategoryId,
            onChanged: (value) => setModalState(() => selectedCategoryId = value),
          ),
          const SizedBox(height: 12),
          _textField(
            nameController,
            'Nama Pengeluaran',
            hint: 'contoh: Belanja mingguan',
          ),
          const SizedBox(height: 12),
          _textField(amountController, 'Jumlah (Rp)', isNumber: true),
          const SizedBox(height: 12),
          _dateField(dateController, 'Tanggal Pengeluaran', setModalState),
          const SizedBox(height: 12),
          _dropdownField(
            label: 'Metode Pembayaran',
            items: _paymentMethods,
            value: selectedMethodId,
            onChanged: (value) => setModalState(() => selectedMethodId = value),
          ),
          const SizedBox(height: 12),
          _textField(notesController, 'Catatan', maxLines: 2),
        ],
      ),
      onSave: () async {
        final amount = _parseAmount(amountController.text);
        final valid = _ensureRequired(
          [
            selectedCategoryId != null,
            selectedMethodId != null,
            nameController.text.trim().isNotEmpty,
            amount != null && amount > 0,
            dateController.text.isNotEmpty,
          ],
          'Lengkapi semua field pengeluaran dengan benar.',
        );
        if (!valid) {
          return;
        }

        if (isEdit) {
          await ApiService.updateRecapExpense(
            recapId: widget.recapId,
            expenseId: existing['id'] as int,
            name: nameController.text.trim(),
            amount: amount!,
            categoryId: selectedCategoryId,
            date: dateController.text,
            paymentMethodId: selectedMethodId,
            notes: notesController.text,
          );
        } else {
          await ApiService.addRecapExpense(
            recapId: widget.recapId,
            categoryId: selectedCategoryId!,
            name: nameController.text.trim(),
            amount: amount!,
            date: dateController.text,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        }

        await _refreshData();
        if (!mounted) {
          return;
        }
        _showSuccess(
          isEdit
              ? 'Pengeluaran berhasil diperbarui'
              : 'Pengeluaran berhasil ditambahkan',
        );
      },
    );
  }

  void _showBusinessExpenseDialog({
    Map<String, dynamic>? existing,
  }) {
    if (!_masterLoaded) {
      return;
    }

    int? selectedBusinessId = existing?['business']?['id'] as int?;
    int? selectedCategoryId = existing?['expense_category']?['id'] as int?;
    int? selectedMethodId = existing?['payment_method']?['id'] as int?;
    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: existing?['amount']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: existing?['expense_date']?.toString() ?? _currentDate(),
    );
    final notesController = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    final isEdit = existing != null;

    _showFormSheet(
      title: isEdit ? 'Edit Pengeluaran Bisnis' : 'Tambah Pengeluaran Bisnis',
      saveLabel: isEdit ? 'Simpan Perubahan' : 'Simpan Pengeluaran Bisnis',
      color: Colors.deepOrange,
      contentBuilder: (setModalState) {
        final categoryItems = _businessExpenseCategoriesFor(selectedBusinessId);
        final categoryExists = categoryItems.any(
          (item) => item['id'] == selectedCategoryId,
        );

        if (!categoryExists) {
          selectedCategoryId = null;
        }

        return Column(
          children: [
            _dropdownField(
              label: 'Bisnis',
              items: _businesses,
              value: selectedBusinessId,
              onChanged: (value) => setModalState(() {
                selectedBusinessId = value;
                selectedCategoryId = null;
              }),
            ),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'Kategori Pengeluaran Bisnis',
              items: categoryItems,
              value: selectedCategoryId,
              onChanged: (value) => setModalState(() => selectedCategoryId = value),
            ),
            const SizedBox(height: 12),
            _textField(
              descriptionController,
              'Deskripsi',
              hint: 'contoh: Beli sparepart customer',
            ),
            const SizedBox(height: 12),
            _textField(amountController, 'Jumlah (Rp)', isNumber: true),
            const SizedBox(height: 12),
            _dateField(dateController, 'Tanggal Pengeluaran', setModalState),
            const SizedBox(height: 12),
            _dropdownField(
              label: 'Metode Pembayaran',
              items: _paymentMethods,
              value: selectedMethodId,
              onChanged: (value) => setModalState(() => selectedMethodId = value),
            ),
            const SizedBox(height: 12),
            _textField(notesController, 'Catatan', maxLines: 2),
          ],
        );
      },
      onSave: () async {
        final amount = _parseAmount(amountController.text);
        final valid = _ensureRequired(
          [
            selectedBusinessId != null,
            selectedCategoryId != null,
            selectedMethodId != null,
            descriptionController.text.trim().isNotEmpty,
            amount != null && amount > 0,
            dateController.text.isNotEmpty,
          ],
          'Lengkapi semua field pengeluaran bisnis dengan benar.',
        );
        if (!valid) {
          return;
        }

        if (isEdit) {
          await ApiService.updateBusinessExpense(
            businessId: selectedBusinessId!,
            expenseId: existing['id'] as int,
            businessExpenseCategoryId: selectedCategoryId!,
            description: descriptionController.text.trim(),
            amount: amount!,
            expenseDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        } else {
          await ApiService.addBusinessExpense(
            businessId: selectedBusinessId!,
            recapId: widget.recapId,
            businessExpenseCategoryId: selectedCategoryId!,
            description: descriptionController.text.trim(),
            amount: amount!,
            expenseDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        }

        await _refreshData();
        if (!mounted) {
          return;
        }
        _showSuccess(
          isEdit
              ? 'Pengeluaran bisnis berhasil diperbarui'
              : 'Pengeluaran bisnis berhasil ditambahkan',
        );
      },
    );
  }

  void _showDebtDialog({
    Map<String, dynamic>? existing,
  }) {
    if (!_masterLoaded) {
      return;
    }

    int? selectedCategoryId = existing?['debt_category']?['id'] as int?;
    final creditorController = TextEditingController(
      text: existing?['creditor_name']?.toString() ?? '',
    );
    final totalController = TextEditingController(
      text: existing?['total_amount']?.toString() ?? '',
    );
    final installmentController = TextEditingController(
      text: existing?['monthly_installment']?.toString() ?? '',
    );
    final monthsController = TextEditingController(
      text: existing?['total_months']?.toString() ?? '',
    );
    final startDateController = TextEditingController(
      text: existing?['start_date']?.toString() ?? _currentDate(),
    );
    final dueDateController = TextEditingController(
      text: existing?['due_date']?.toString() ?? _currentDate(),
    );
    final notesController = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    final isEdit = existing != null;

    _showFormSheet(
      title: isEdit ? 'Edit Hutang' : 'Tambah Hutang',
      saveLabel: isEdit ? 'Simpan Perubahan' : 'Simpan Hutang',
      color: Colors.orange,
      contentBuilder: (setModalState) => Column(
        children: [
          _dropdownField(
            label: 'Jenis Hutang',
            items: _debtCategories,
            value: selectedCategoryId,
            onChanged: (value) => setModalState(() => selectedCategoryId = value),
          ),
          const SizedBox(height: 12),
          _textField(
            creditorController,
            'Nama Pemberi Hutang',
            hint: 'contoh: Leasing Motor',
          ),
          const SizedBox(height: 12),
          _textField(totalController, 'Total Hutang (Rp)', isNumber: true),
          const SizedBox(height: 12),
          _textField(
            installmentController,
            'Cicilan per Bulan (Rp)',
            isNumber: true,
          ),
          const SizedBox(height: 12),
          _textField(monthsController, 'Jumlah Bulan', isNumber: true),
          const SizedBox(height: 12),
          _dateField(startDateController, 'Tanggal Mulai', setModalState),
          const SizedBox(height: 12),
          _dateField(dueDateController, 'Tanggal Jatuh Tempo', setModalState),
          const SizedBox(height: 12),
          _textField(notesController, 'Catatan', maxLines: 2),
        ],
      ),
      onSave: () async {
        final totalAmount = _parseAmount(totalController.text);
        final installment = _parseAmount(installmentController.text);
        final totalMonths = int.tryParse(monthsController.text.trim());
        final valid = _ensureRequired(
          [
            selectedCategoryId != null,
            creditorController.text.trim().isNotEmpty,
            totalAmount != null && totalAmount > 0,
            installment != null && installment > 0,
            totalMonths != null && totalMonths > 0,
            startDateController.text.isNotEmpty,
            dueDateController.text.isNotEmpty,
          ],
          'Lengkapi semua field hutang dengan benar.',
        );
        if (!valid) {
          return;
        }

        if (isEdit) {
          await ApiService.updateDebt(
            id: existing['id'] as int,
            debtCategoryId: selectedCategoryId!,
            creditorName: creditorController.text.trim(),
            totalAmount: totalAmount!,
            monthlyInstallment: installment!,
            totalMonths: totalMonths!,
            startDate: startDateController.text,
            dueDate: dueDateController.text,
            notes: notesController.text,
          );
        } else {
          await ApiService.addDebt(
            recapId: widget.recapId,
            debtCategoryId: selectedCategoryId!,
            creditorName: creditorController.text.trim(),
            totalAmount: totalAmount!,
            monthlyInstallment: installment!,
            totalMonths: totalMonths!,
            startDate: startDateController.text,
            dueDate: dueDateController.text,
            notes: notesController.text,
          );
        }

        await _refreshData(reloadMaster: true);
        if (!mounted) {
          return;
        }
        _showSuccess(
          isEdit ? 'Hutang berhasil diperbarui' : 'Hutang berhasil ditambahkan',
        );
      },
    );
  }

  void _showDebtPaymentDialog({
    Map<String, dynamic>? existing,
  }) {
    if (!_masterLoaded) {
      return;
    }

    if (_debtItems.isEmpty) {
      _showError('Belum ada hutang. Tambahkan hutang terlebih dahulu.');
      return;
    }

    int? selectedDebtId = existing?['debt_item']?['id'] as int?;
    int? selectedMethodId = existing?['payment_method']?['id'] as int?;
    String selectedStatus = existing?['status']?.toString() ?? 'paid';
    final amountController = TextEditingController(
      text: existing?['amount_paid']?.toString() ?? '',
    );
    final dateController = TextEditingController(
      text: existing?['payment_date']?.toString() ?? _currentDate(),
    );
    final notesController = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    final isEdit = existing != null;

    _showFormSheet(
      title: isEdit ? 'Edit Pembayaran Hutang' : 'Bayar Cicilan Hutang',
      saveLabel: isEdit ? 'Simpan Perubahan' : 'Simpan Pembayaran',
      color: Colors.red,
      contentBuilder: (setModalState) => Column(
        children: [
          _dropdownField(
            label: 'Pilih Hutang',
            items: _debtItems,
            value: selectedDebtId,
            labelBuilder: (item) =>
                '${item['creditor_name']} - ${_formatRupiah(item['monthly_installment'])}/bln',
            onChanged: (value) => setModalState(() {
              selectedDebtId = value;
              if (!isEdit && value != null) {
                final debt = _debtItems.firstWhere((item) => item['id'] == value);
                amountController.text = debt['monthly_installment'].toString();
              }
            }),
          ),
          const SizedBox(height: 12),
          _textField(amountController, 'Jumlah Bayar (Rp)', isNumber: true),
          const SizedBox(height: 12),
          _dateField(dateController, 'Tanggal Pembayaran', setModalState),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status Pembayaran',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'paid', child: Text('Lunas')),
              DropdownMenuItem(value: 'partial', child: Text('Parsial')),
              DropdownMenuItem(value: 'skipped', child: Text('Lewati')),
            ],
            onChanged: (value) =>
                setModalState(() => selectedStatus = value ?? 'paid'),
          ),
          const SizedBox(height: 12),
          _dropdownField(
            label: 'Metode Pembayaran',
            items: _paymentMethods,
            value: selectedMethodId,
            onChanged: (value) => setModalState(() => selectedMethodId = value),
          ),
          const SizedBox(height: 12),
          _textField(notesController, 'Catatan', maxLines: 2),
        ],
      ),
      onSave: () async {
        final amount = _parseAmount(amountController.text);
        final valid = _ensureRequired(
          [
            selectedDebtId != null,
            selectedMethodId != null,
            amount != null && amount >= 0,
            dateController.text.isNotEmpty,
          ],
          'Lengkapi semua field pembayaran hutang dengan benar.',
        );
        if (!valid) {
          return;
        }

        if (isEdit) {
          await ApiService.updateDebtPayment(
            recapId: widget.recapId,
            paymentId: existing['id'] as int,
            amountPaid: amount!,
            paymentDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            status: selectedStatus,
            notes: notesController.text,
          );
        } else {
          await ApiService.payDebt(
            debtId: selectedDebtId!,
            recapId: widget.recapId,
            amountPaid: amount!,
            paymentDate: dateController.text,
            paymentMethodId: selectedMethodId!,
            status: selectedStatus,
            notes: notesController.text,
          );
        }

        await _refreshData(reloadMaster: true);
        if (!mounted) {
          return;
        }
        _showSuccess(
          isEdit
              ? 'Pembayaran hutang berhasil diperbarui'
              : 'Pembayaran hutang berhasil ditambahkan',
        );
      },
    );
  }

  void _showBudgetDialog({
    Map<String, dynamic>? existing,
  }) {
    if (!_masterLoaded) {
      return;
    }

    int? selectedCategoryId = existing?['budget_category']?['id'] as int?;
    int? selectedMethodId = existing?['payment_method']?['id'] as int?;
    final plannedController = TextEditingController(
      text: existing?['planned_amount']?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    final isEdit = existing != null;

    _showFormSheet(
      title: isEdit ? 'Edit Alokasi Budget' : 'Tambah Alokasi Budget',
      saveLabel: isEdit ? 'Simpan Perubahan' : 'Simpan Budget',
      color: Colors.purple,
      contentBuilder: (setModalState) => Column(
        children: [
          _dropdownField(
            label: 'Kategori Budget',
            items: _budgetCategories,
            value: selectedCategoryId,
            onChanged: (value) => setModalState(() => selectedCategoryId = value),
          ),
          const SizedBox(height: 12),
          _textField(plannedController, 'Jumlah Budget (Rp)', isNumber: true),
          const SizedBox(height: 12),
          _dropdownField(
            label: 'Metode Pembayaran',
            items: _paymentMethods,
            value: selectedMethodId,
            onChanged: (value) => setModalState(() => selectedMethodId = value),
          ),
          const SizedBox(height: 12),
          _textField(notesController, 'Catatan', maxLines: 2),
        ],
      ),
      onSave: () async {
        final plannedAmount = _parseAmount(plannedController.text);
        final valid = _ensureRequired(
          [
            selectedCategoryId != null,
            selectedMethodId != null,
            plannedAmount != null && plannedAmount > 0,
          ],
          'Lengkapi semua field budget dengan benar.',
        );
        if (!valid) {
          return;
        }

        if (isEdit) {
          await ApiService.updateBudgetAllocation(
            id: existing['id'] as int,
            budgetCategoryId: selectedCategoryId!,
            plannedAmount: plannedAmount!,
            paymentMethodId: selectedMethodId!,
            actualAmount: double.tryParse(
              existing['actual_amount']?.toString() ?? '',
            ),
            notes: notesController.text,
          );
        } else {
          await ApiService.addBudgetAllocation(
            recapId: widget.recapId,
            budgetCategoryId: selectedCategoryId!,
            plannedAmount: plannedAmount!,
            paymentMethodId: selectedMethodId!,
            notes: notesController.text,
          );
        }

        await _refreshData();
        if (!mounted) {
          return;
        }
        _showSuccess(
          isEdit
              ? 'Alokasi budget berhasil diperbarui'
              : 'Alokasi budget berhasil ditambahkan',
        );
      },
    );
  }

  Future<void> _handleSummaryEdit(String type, Map<String, dynamic> item) async {
    switch (type) {
      case 'income_entry':
        _showIncomeEntryDialog(existing: item);
        break;
      case 'business_income':
        _showBusinessIncomeDialog(existing: item);
        break;
      case 'expense':
        _showExpenseDialog(existing: item);
        break;
      case 'business_expense':
        _showBusinessExpenseDialog(existing: item);
        break;
      case 'debt':
        _showDebtDialog(existing: item);
        break;
      case 'debt_payment':
        _showDebtPaymentDialog(existing: item);
        break;
      case 'budget':
        _showBudgetDialog(existing: item);
        break;
    }
  }

  Future<void> _handleSummaryDelete(String type, Map<String, dynamic> item) async {
    switch (type) {
      case 'income_entry':
        await _executeDelete(
          'pemasukan',
          () => ApiService.deleteIncomeEntry(
            recapId: widget.recapId,
            entryId: item['id'] as int,
          ),
        );
        break;
      case 'business_income':
        await _executeDelete(
          'income bisnis',
          () => ApiService.deleteBusinessIncome(
            recapId: widget.recapId,
            entryId: item['id'] as int,
          ),
        );
        break;
      case 'expense':
        await _executeDelete(
          'pengeluaran bulanan',
          () => ApiService.deleteRecapExpense(
            recapId: widget.recapId,
            expenseId: item['id'] as int,
          ),
        );
        break;
      case 'business_expense':
        await _executeDelete(
          'pengeluaran bisnis',
          () => ApiService.deleteBusinessExpense(
            businessId: item['business']['id'] as int,
            expenseId: item['id'] as int,
          ),
        );
        break;
      case 'debt':
        await _executeDelete(
          'hutang',
          () => ApiService.deleteDebt(item['id'] as int),
          reloadMaster: true,
        );
        break;
      case 'debt_payment':
        await _executeDelete(
          'pembayaran hutang',
          () => ApiService.deleteDebtPayment(
            recapId: widget.recapId,
            paymentId: item['id'] as int,
          ),
          reloadMaster: true,
        );
        break;
      case 'budget':
        await _executeDelete(
          'alokasi budget',
          () => ApiService.deleteBudgetAllocation(item['id'] as int),
        );
        break;
    }
  }

  Widget _actionMenu({
    required VoidCallback onEdit,
    required Future<void> Function() onDelete,
  }) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'edit') {
          onEdit();
          return;
        }
        await onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required dynamic amount,
    required Color color,
    required IconData icon,
    VoidCallback? onEdit,
    Future<void> Function()? onDelete,
    String? note,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatRupiah(amount),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onEdit != null && onDelete != null)
                  _actionMenu(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeTab(Map<String, dynamic> report) {
    final incomeEntries = _listOfMaps(report['income_entries']);
    final businessIncomes = _listOfMaps(report['business_incomes']);
    final finalized = _isFinalized(report);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.green),
                  label: const Text(
                    'Tambah Income',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: finalized ? null : () => _showIncomeEntryDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.business, color: Colors.blue),
                  label: const Text(
                    'Income Bisnis',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed:
                      finalized ? null : () => _showBusinessIncomeDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (incomeEntries.isNotEmpty) ...[
            _sectionHeader('Pemasukan Umum', Colors.green),
            const SizedBox(height: 8),
            ...incomeEntries.map(
              (entry) => _actionCard(
                title: entry['income_source']?['name']?.toString() ?? 'Income',
                subtitle:
                    '${_formatDateLabel(entry['received_date']?.toString())} • ${entry['payment_method']?['name'] ?? '-'}',
                amount: entry['amount'],
                color: Colors.green,
                icon: Icons.attach_money,
                note: entry['notes']?.toString(),
                onEdit: finalized
                    ? null
                    : () => _showIncomeEntryDialog(existing: entry),
                onDelete: finalized
                    ? null
                    : () => _executeDelete(
                          'pemasukan',
                          () => ApiService.deleteIncomeEntry(
                            recapId: widget.recapId,
                            entryId: entry['id'] as int,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (businessIncomes.isNotEmpty) ...[
            _sectionHeader('Income Bisnis', Colors.blue),
            const SizedBox(height: 8),
            ...businessIncomes.map(
              (entry) => _actionCard(
                title: entry['description']?.toString() ?? 'Income Bisnis',
                subtitle:
                    '${entry['business']?['name'] ?? '-'} • ${_formatDateLabel(entry['received_date']?.toString())}',
                amount: entry['amount'],
                color: Colors.blue,
                icon: Icons.business,
                note: entry['notes']?.toString(),
                onEdit: finalized
                    ? null
                    : () => _showBusinessIncomeDialog(existing: entry),
                onDelete: finalized
                    ? null
                    : () => _executeDelete(
                          'income bisnis',
                          () => ApiService.deleteBusinessIncome(
                            recapId: widget.recapId,
                            entryId: entry['id'] as int,
                          ),
                        ),
              ),
            ),
          ],
          if (incomeEntries.isEmpty && businessIncomes.isEmpty)
            _emptyState(
              'Belum ada pemasukan.\nTekan tombol di atas untuk menambah.',
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseTab(Map<String, dynamic> report) {
    final expenses = _listOfMaps(report['expenses']);
    final businessExpenses = _listOfMaps(report['business_expenses']);
    final finalized = _isFinalized(report);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_bag, color: Colors.red),
                  label: const Text(
                    'Pengeluaran Bulanan',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: finalized ? null : () => _showExpenseDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.storefront, color: Colors.deepOrange),
                  label: const Text(
                    'Pengeluaran Bisnis',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                  onPressed:
                      finalized ? null : () => _showBusinessExpenseDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expenses.isNotEmpty) ...[
            _sectionHeader('Pengeluaran Bulanan', Colors.red),
            const SizedBox(height: 8),
            ...expenses.map(
              (expense) => _actionCard(
                title: expense['name']?.toString() ?? 'Pengeluaran',
                subtitle:
                    '${expense['category']?['name'] ?? '-'} • ${_formatDateLabel(expense['date']?.toString())}',
                amount: expense['amount'],
                color: Colors.red,
                icon: Icons.receipt_long,
                note: expense['notes']?.toString(),
                onEdit: finalized
                    ? null
                    : () => _showExpenseDialog(existing: expense),
                onDelete: finalized
                    ? null
                    : () => _executeDelete(
                          'pengeluaran bulanan',
                          () => ApiService.deleteRecapExpense(
                            recapId: widget.recapId,
                            expenseId: expense['id'] as int,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (businessExpenses.isNotEmpty) ...[
            _sectionHeader('Pengeluaran Bisnis', Colors.deepOrange),
            const SizedBox(height: 8),
            ...businessExpenses.map(
              (expense) => _actionCard(
                title: expense['description']?.toString() ?? 'Pengeluaran Bisnis',
                subtitle:
                    '${expense['business']?['name'] ?? '-'} • ${expense['expense_category']?['name'] ?? '-'}',
                amount: expense['amount'],
                color: Colors.deepOrange,
                icon: Icons.business_center,
                note:
                    '${_formatDateLabel(expense['expense_date']?.toString())}${(expense['notes']?.toString().isNotEmpty ?? false) ? ' • ${expense['notes']}' : ''}',
                onEdit: finalized
                    ? null
                    : () => _showBusinessExpenseDialog(existing: expense),
                onDelete: finalized
                    ? null
                    : () => _executeDelete(
                          'pengeluaran bisnis',
                          () => ApiService.deleteBusinessExpense(
                            businessId: expense['business']['id'] as int,
                            expenseId: expense['id'] as int,
                          ),
                        ),
              ),
            ),
          ],
          if (expenses.isEmpty && businessExpenses.isEmpty)
            _emptyState(
              'Belum ada pengeluaran.\nTekan tombol di atas untuk menambah.',
            ),
        ],
      ),
    );
  }

  Widget _buildDebtTab(Map<String, dynamic> report) {
    final debts = _listOfMaps(report['debts']);
    final debtPayments = _listOfMaps(report['debt_payments']);
    final finalized = _isFinalized(report);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.orange),
                  label: const Text(
                    'Tambah Hutang',
                    style: TextStyle(color: Colors.orange),
                  ),
                  onPressed: finalized ? null : () => _showDebtDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.payment, color: Colors.red),
                  label: const Text(
                    'Bayar Cicilan',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed:
                      finalized ? null : () => _showDebtPaymentDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (debts.isNotEmpty) ...[
            _sectionHeader('Daftar Hutang', Colors.orange),
            const SizedBox(height: 8),
            ...debts.map(
              (debt) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.credit_card, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  debt['creditor_name']?.toString() ?? 'Hutang',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${debt['debt_category']?['name'] ?? '-'} • Mulai ${_formatDateLabel(debt['start_date']?.toString())}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatRupiah(debt['total_amount']),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!finalized)
                            _actionMenu(
                              onEdit: () => _showDebtDialog(existing: debt),
                              onDelete: () => _executeDelete(
                                'hutang',
                                () => ApiService.deleteDebt(debt['id'] as int),
                                reloadMaster: true,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (debt['total_months'] ?? 0) > 0
                              ? ((debt['total_months'] as num) -
                                        (debt['remaining_months'] as num? ?? 0)) /
                                    (debt['total_months'] as num)
                              : 0,
                          backgroundColor: Colors.orange.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cicilan ${_formatRupiah(debt['monthly_installment'])}/bln • Sisa ${debt['remaining_months'] ?? 0} bulan',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if ((debt['notes']?.toString().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 4),
                        Text(
                          debt['notes'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (debtPayments.isNotEmpty) ...[
            _sectionHeader('Pembayaran Cicilan di Rekap Ini', Colors.red),
            const SizedBox(height: 8),
            ...debtPayments.map(
              (payment) => _actionCard(
                title:
                    payment['debt_item']?['creditor_name']?.toString() ?? 'Pembayaran Hutang',
                subtitle:
                    '${payment['status']?.toString().toUpperCase()} • ${_formatDateLabel(payment['payment_date']?.toString())}',
                amount: payment['amount_paid'],
                color: Colors.red,
                icon: Icons.payment,
                note: payment['notes']?.toString(),
                onEdit: finalized
                    ? null
                    : () => _showDebtPaymentDialog(existing: payment),
                onDelete: finalized
                    ? null
                    : () => _executeDelete(
                          'pembayaran hutang',
                          () => ApiService.deleteDebtPayment(
                            recapId: widget.recapId,
                            paymentId: payment['id'] as int,
                          ),
                          reloadMaster: true,
                        ),
              ),
            ),
          ],
          if (debts.isEmpty && debtPayments.isEmpty)
            _emptyState('Belum ada data hutang atau pembayaran cicilan.'),
        ],
      ),
    );
  }

  Widget _buildBudgetTab(Map<String, dynamic> report) {
    final budgets = _listOfMaps(report['budget_allocations']);
    final finalized = _isFinalized(report);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, color: Colors.purple),
              label: const Text(
                'Tambah Alokasi Budget',
                style: TextStyle(color: Colors.purple),
              ),
              onPressed: finalized ? null : () => _showBudgetDialog(),
            ),
          ),
          const SizedBox(height: 16),
          if (budgets.isEmpty)
            _emptyState(
              'Belum ada alokasi budget.\nTekan tombol di atas untuk menambah.',
            )
          else ...[
            _sectionHeader('Alokasi Budget Bulan Ini', Colors.purple),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Budget',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatRupiah(
                      budgets.fold<double>(
                        0,
                        (sum, item) =>
                            sum + (_parseAmount(item['planned_amount'].toString()) ?? 0),
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...budgets.map(
              (budget) => _actionCard(
                title: budget['budget_category']?['name']?.toString() ?? 'Budget',
                subtitle:
                    '${budget['payment_method']?['name'] ?? '-'} • Aktual ${_formatRupiah(budget['actual_amount'] ?? 0)}',
                amount: budget['planned_amount'],
                color: Colors.purple,
                icon: Icons.pie_chart,
                note: budget['notes']?.toString(),
                onEdit: finalized
                    ? null
                    : () => _showBudgetDialog(existing: budget),
                onDelete: finalized
                    ? null
                    : () => _executeDelete(
                          'alokasi budget',
                          () => ApiService.deleteBudgetAllocation(
                            budget['id'] as int,
                          ),
                        ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _recentTransactions(Map<String, dynamic> report) {
    final items = <Map<String, dynamic>>[];

    for (final item in _listOfMaps(report['income_entries'])) {
      items.add({
        ...item,
        'record_type': 'income_entry',
        'record_title': item['income_source']?['name'] ?? 'Pemasukan',
        'record_subtitle': _formatDateLabel(item['received_date']?.toString()),
        'record_amount': item['amount'],
        'record_color': Colors.green,
        'record_icon': Icons.attach_money,
        'record_date': item['received_date'],
      });
    }

    for (final item in _listOfMaps(report['business_incomes'])) {
      items.add({
        ...item,
        'record_type': 'business_income',
        'record_title': item['description'] ?? 'Income Bisnis',
        'record_subtitle': item['business']?['name'] ?? '-',
        'record_amount': item['amount'],
        'record_color': Colors.blue,
        'record_icon': Icons.business,
        'record_date': item['received_date'],
      });
    }

    for (final item in _listOfMaps(report['expenses'])) {
      items.add({
        ...item,
        'record_type': 'expense',
        'record_title': item['name'] ?? 'Pengeluaran',
        'record_subtitle': item['category']?['name'] ?? '-',
        'record_amount': item['amount'],
        'record_color': Colors.red,
        'record_icon': Icons.receipt_long,
        'record_date': item['date'],
      });
    }

    for (final item in _listOfMaps(report['business_expenses'])) {
      items.add({
        ...item,
        'record_type': 'business_expense',
        'record_title': item['description'] ?? 'Pengeluaran Bisnis',
        'record_subtitle': item['business']?['name'] ?? '-',
        'record_amount': item['amount'],
        'record_color': Colors.deepOrange,
        'record_icon': Icons.business_center,
        'record_date': item['expense_date'],
      });
    }

    for (final item in _listOfMaps(report['debt_payments'])) {
      items.add({
        ...item,
        'record_type': 'debt_payment',
        'record_title':
            'Cicilan ${item['debt_item']?['creditor_name'] ?? 'Hutang'}',
        'record_subtitle': _formatDateLabel(item['payment_date']?.toString()),
        'record_amount': item['amount_paid'],
        'record_color': Colors.red,
        'record_icon': Icons.payment,
        'record_date': item['payment_date'],
      });
    }

    for (final item in _listOfMaps(report['budget_allocations'])) {
      items.add({
        ...item,
        'record_type': 'budget',
        'record_title': item['budget_category']?['name'] ?? 'Budget',
        'record_subtitle': item['payment_method']?['name'] ?? '-',
        'record_amount': item['planned_amount'],
        'record_color': Colors.purple,
        'record_icon': Icons.pie_chart,
        'record_date': '',
      });
    }

    for (final item in _listOfMaps(report['debts'])) {
      items.add({
        ...item,
        'record_type': 'debt',
        'record_title': item['creditor_name'] ?? 'Hutang',
        'record_subtitle': item['debt_category']?['name'] ?? '-',
        'record_amount': item['total_amount'],
        'record_color': Colors.orange,
        'record_icon': Icons.credit_card,
        'record_date': item['start_date'],
      });
    }

    items.sort((left, right) {
      final rightDate = _tryParseDate(right['record_date']?.toString() ?? '');
      final leftDate = _tryParseDate(left['record_date']?.toString() ?? '');
      if (rightDate == null && leftDate == null) {
        return 0;
      }
      if (rightDate == null) {
        return -1;
      }
      if (leftDate == null) {
        return 1;
      }
      return rightDate.compareTo(leftDate);
    });

    return items;
  }

  Widget _buildSummaryTab(Map<String, dynamic> report) {
    final finalized = _isFinalized(report);
    final recentTransactions = _recentTransactions(report).take(8).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.indigo, Colors.indigoAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Akhir Rekap',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRupiah(report['ending_balance'] ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _summaryCard(
            'Total Pemasukan',
            _formatRupiah(report['total_income'] ?? 0),
            Colors.green,
            Icons.arrow_downward,
          ),
          _summaryCard(
            'Total Pengeluaran',
            _formatRupiah(report['total_expense'] ?? 0),
            Colors.red,
            Icons.arrow_upward,
          ),
          _summaryCard(
            'Total Hutang Aktif',
            _formatRupiah(report['total_debt'] ?? 0),
            Colors.orange,
            Icons.credit_card,
          ),
          _summaryCard(
            'Total Budget',
            _formatRupiah(report['total_budget'] ?? 0),
            Colors.purple,
            Icons.pie_chart,
          ),
          const SizedBox(height: 16),
          if (recentTransactions.isNotEmpty) ...[
            _sectionHeader('Aktivitas Terbaru', Colors.indigo),
            const SizedBox(height: 8),
            ...recentTransactions.map(
              (item) => _actionCard(
                title: item['record_title']?.toString() ?? '-',
                subtitle:
                    '${item['record_subtitle'] ?? '-'}${(_formatDateLabel(item['record_date']?.toString()) != '-' && item['record_subtitle'] != _formatDateLabel(item['record_date']?.toString())) ? ' • ${_formatDateLabel(item['record_date']?.toString())}' : ''}',
                amount: item['record_amount'],
                color: item['record_color'] as Color,
                icon: item['record_icon'] as IconData,
                note: item['notes']?.toString(),
                onEdit: finalized
                    ? null
                    : () => _handleSummaryEdit(
                          item['record_type'] as String,
                          item,
                        ),
                onDelete: finalized
                    ? null
                    : () => _handleSummaryDelete(
                          item['record_type'] as String,
                          item,
                        ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.indigo),
                foregroundColor: Colors.indigo,
              ),
              icon: const Icon(Icons.assessment),
              label: const Text(
                'Lihat Laporan Lengkap',
                style: TextStyle(fontSize: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecapReportPage(
                      recapId: widget.recapId,
                      title: widget.title,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          if (!finalized)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.lock),
                label: const Text(
                  'Finalisasi Rekap',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Finalisasi Rekap'),
                      content: const Text(
                        'Setelah difinalisasi, rekap tidak bisa diubah lagi. Lanjutkan?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Finalisasi'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) {
                    return;
                  }

                  try {
                    await ApiService.finalizeRecap(widget.recapId);
                    await _refreshData();
                    if (!mounted) {
                      return;
                    }
                    _showSuccess('Rekap berhasil difinalisasi');
                  } catch (error) {
                    _showError('Gagal finalisasi rekap: $error');
                  }
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Rekap sudah difinalisasi',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap ${widget.title}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.attach_money), text: 'Income'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Pengeluaran'),
            Tab(icon: Icon(Icons.credit_card), text: 'Hutang'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Budget'),
            Tab(icon: Icon(Icons.summarize), text: 'Summary'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final report = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildIncomeTab(report),
              _buildExpenseTab(report),
              _buildDebtTab(report),
              _buildBudgetTab(report),
              _buildSummaryTab(report),
            ],
          );
        },
      ),
    );
  }
}
