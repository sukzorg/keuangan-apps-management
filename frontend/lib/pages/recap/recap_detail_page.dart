import 'package:flutter/material.dart';
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

  // Master data untuk dropdown
  List<dynamic> _incomeSources = [];
  List<dynamic> _paymentMethods = [];
  List<dynamic> _businesses = [];
  List<dynamic> _debtCategories = [];
  List<dynamic> _budgetCategories = [];
  List<dynamic> _debts = [];
  bool _masterLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _loadMasterData() async {
    try {
      final results = await Future.wait([
        ApiService.getIncomeSources(),
        ApiService.getPaymentMethods(),
        ApiService.getBusinesses(),
        ApiService.getDebtCategories(),
        ApiService.getBudgetCategories(),
        ApiService.getDebts(),
      ]);
      setState(() {
        _incomeSources = results[0];
        _paymentMethods = results[1];
        _businesses = results[2];
        _debtCategories = results[3];
        _budgetCategories = results[4];
        _debts = results[5];
        _masterLoaded = true;
      });
    } catch (e) {
      debugPrint("Error load master: $e");
    }
  }

  String _formatRupiah(dynamic value) {
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return "Rp ${(num / 1000000).toStringAsFixed(1)} Jt";
    if (num >= 1000) return "Rp ${(num / 1000).toStringAsFixed(0)} Rb";
    return "Rp ${num.toStringAsFixed(0)}";
  }

  // ── DIALOG: Tambah Income Entry ──────────────────────────────────────
  void _showAddIncomeDialog() {
    if (!_masterLoaded) return;
    int? selectedSourceId;
    int? selectedMethodId;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _bottomSheet(
        ctx: ctx,
        title: "Tambah Pemasukan",
        color: Colors.green,
        children: [
          _dropdown(
            "Sumber Pemasukan",
            _incomeSources,
            (v) => selectedSourceId = v,
          ),
          const SizedBox(height: 12),
          _inputField(amountCtrl, "Jumlah (Rp)", isNumber: true),
          const SizedBox(height: 12),
          _dropdown(
            "Metode Pembayaran",
            _paymentMethods,
            (v) => selectedMethodId = v,
          ),
          const SizedBox(height: 12),
          _inputField(notesCtrl, "Catatan (opsional)"),
        ],
        onSave: () async {
          if (selectedSourceId == null ||
              selectedMethodId == null ||
              amountCtrl.text.isEmpty) {
            _showError("Lengkapi semua field");
            return;
          }
          await ApiService.addIncomeEntry(
            recapId: widget.recapId,
            incomeSourceId: selectedSourceId!,
            amount: double.parse(amountCtrl.text),
            receivedDate: DateTime.now().toString().substring(0, 10),
            paymentMethodId: selectedMethodId!,
            notes: notesCtrl.text,
          );
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          Navigator.pop(ctx);
          _loadReport();
          _showSuccess("Pemasukan berhasil ditambahkan!");
        },
        saveLabel: "Simpan Pemasukan",
      ),
    );
  }

  // ── DIALOG: Tambah Business Income ──────────────────────────────────
  void _showAddBusinessIncomeDialog() {
    if (!_masterLoaded) return;
    int? selectedBusinessId;
    int? selectedMethodId;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _bottomSheet(
        ctx: ctx,
        title: "Tambah Income Bisnis",
        color: Colors.blue,
        children: [
          _dropdown("Bisnis", _businesses, (v) => selectedBusinessId = v),
          const SizedBox(height: 12),
          _inputField(
            descCtrl,
            "Deskripsi",
            hint: "contoh: Wedding photo Bandung",
          ),
          const SizedBox(height: 12),
          _inputField(amountCtrl, "Jumlah (Rp)", isNumber: true),
          const SizedBox(height: 12),
          _dropdown(
            "Metode Pembayaran",
            _paymentMethods,
            (v) => selectedMethodId = v,
          ),
          const SizedBox(height: 12),
          _inputField(notesCtrl, "Catatan (opsional)"),
        ],
        onSave: () async {
          if (selectedBusinessId == null ||
              selectedMethodId == null ||
              amountCtrl.text.isEmpty ||
              descCtrl.text.isEmpty) {
            _showError("Lengkapi semua field");
            return;
          }
          await ApiService.addBusinessIncome(
            recapId: widget.recapId,
            businessId: selectedBusinessId!,
            description: descCtrl.text,
            amount: double.parse(amountCtrl.text),
            receivedDate: DateTime.now().toString().substring(0, 10),
            paymentMethodId: selectedMethodId!,
            notes: notesCtrl.text,
          );
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          Navigator.pop(ctx);
          _loadReport();
          _showSuccess("Income bisnis berhasil ditambahkan!");
        },
        saveLabel: "Simpan",
      ),
    );
  }

  // ── DIALOG: Tambah Hutang ────────────────────────────────────────────
  void _showAddDebtDialog() {
    if (!_masterLoaded) return;
    int? selectedCategoryId;
    final creditorCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final installmentCtrl = TextEditingController();
    final monthsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _bottomSheet(
        ctx: ctx,
        title: "Tambah Hutang",
        color: Colors.orange,
        children: [
          _dropdown(
            "Jenis Hutang",
            _debtCategories,
            (v) => selectedCategoryId = v,
          ),
          const SizedBox(height: 12),
          _inputField(
            creditorCtrl,
            "Nama Pemberi Hutang",
            hint: "contoh: Leasing Motor",
          ),
          const SizedBox(height: 12),
          _inputField(totalCtrl, "Total Hutang (Rp)", isNumber: true),
          const SizedBox(height: 12),
          _inputField(
            installmentCtrl,
            "Cicilan per Bulan (Rp)",
            isNumber: true,
          ),
          const SizedBox(height: 12),
          _inputField(
            monthsCtrl,
            "Jumlah Bulan",
            isNumber: true,
            hint: "contoh: 12",
          ),
        ],
        onSave: () async {
          if (selectedCategoryId == null ||
              creditorCtrl.text.isEmpty ||
              totalCtrl.text.isEmpty ||
              installmentCtrl.text.isEmpty ||
              monthsCtrl.text.isEmpty) {
            _showError("Lengkapi semua field");
            return;
          }
          final today = DateTime.now().toString().substring(0, 10);
          await ApiService.addDebt(
            debtCategoryId: selectedCategoryId!,
            creditorName: creditorCtrl.text,
            totalAmount: double.parse(totalCtrl.text),
            monthlyInstallment: double.parse(installmentCtrl.text),
            totalMonths: int.parse(monthsCtrl.text),
            startDate: today,
            dueDate: today,
          );
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          Navigator.pop(ctx);
          _loadReport();
          // Refresh daftar hutang untuk dropdown bayar cicilan
          final debts = await ApiService.getDebts();
          setState(() => _debts = debts);
          _showSuccess("Hutang berhasil ditambahkan!");
        },
        saveLabel: "Simpan Hutang",
      ),
    );
  }

  // ── DIALOG: Bayar Cicilan Hutang ────────────────────────────────────
  void _showPayDebtDialog() {
    if (!_masterLoaded) return;
    if (_debts.isEmpty) {
      _showError("Belum ada hutang. Tambah hutang dulu.");
      return;
    }

    int? selectedDebtId;
    int? selectedMethodId;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _bottomSheet(
        ctx: ctx,
        title: "Bayar Cicilan",
        color: Colors.red,
        children: [
          // Dropdown pilih hutang — tampilkan nama + sisa cicilan
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: "Pilih Hutang",
              border: OutlineInputBorder(),
            ),
            items: _debts.map((d) {
              return DropdownMenuItem<int>(
                value: d['id'],
                child: Text(
                  "${d['creditor_name']} — ${_formatRupiah(d['monthly_installment'])}/bln",
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (v) {
              selectedDebtId = v;
              // Auto-isi jumlah dengan cicilan bulanan
              if (v != null) {
                final debt = _debts.firstWhere((d) => d['id'] == v);
                amountCtrl.text = debt['monthly_installment'].toString();
              }
            },
          ),
          const SizedBox(height: 12),
          _inputField(amountCtrl, "Jumlah Bayar (Rp)", isNumber: true),
          const SizedBox(height: 12),
          _dropdown(
            "Metode Pembayaran",
            _paymentMethods,
            (v) => selectedMethodId = v,
          ),
          const SizedBox(height: 12),
          _inputField(
            notesCtrl,
            "Catatan (opsional)",
            hint: "contoh: Cicilan ke-3",
          ),
        ],
        onSave: () async {
          if (selectedDebtId == null ||
              selectedMethodId == null ||
              amountCtrl.text.isEmpty) {
            _showError("Lengkapi semua field");
            return;
          }
          await ApiService.payDebt(
            debtId: selectedDebtId!,
            recapId: widget.recapId,
            amountPaid: double.parse(amountCtrl.text),
            paymentDate: DateTime.now().toString().substring(0, 10),
            paymentMethodId: selectedMethodId!,
            notes: notesCtrl.text,
          );
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          Navigator.pop(ctx);
          _loadReport();
          final debts = await ApiService.getDebts();
          setState(() => _debts = debts);
          _showSuccess("Cicilan berhasil dibayar!");
        },
        saveLabel: "Bayar Sekarang",
      ),
    );
  }

  // ── DIALOG: Tambah Budget Bulanan ───────────────────────────────────
  void _showAddBudgetDialog() {
    if (!_masterLoaded) return;
    int? selectedCategoryId;
    int? selectedMethodId;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _bottomSheet(
        ctx: ctx,
        title: "Tambah Alokasi Budget",
        color: Colors.purple,
        children: [
          _dropdown(
            "Kategori Budget",
            _budgetCategories,
            (v) => selectedCategoryId = v,
          ),
          const SizedBox(height: 12),
          _inputField(amountCtrl, "Jumlah Budget (Rp)", isNumber: true),
          const SizedBox(height: 12),
          _dropdown(
            "Metode Pembayaran",
            _paymentMethods,
            (v) => selectedMethodId = v,
          ),
          const SizedBox(height: 12),
          _inputField(notesCtrl, "Catatan (opsional)"),
        ],
        onSave: () async {
          if (selectedCategoryId == null ||
              selectedMethodId == null ||
              amountCtrl.text.isEmpty) {
            _showError("Lengkapi semua field");
            return;
          }
          await ApiService.addBudgetAllocation(
            recapId: widget.recapId,
            budgetCategoryId: selectedCategoryId!,
            plannedAmount: double.parse(amountCtrl.text),
            paymentMethodId: selectedMethodId!,
            notes: notesCtrl.text,
          );
          if (!mounted) return;
          // ignore: use_build_context_synchronously
          Navigator.pop(ctx);
          _loadReport();
          _showSuccess("Budget berhasil dialokasikan!");
        },
        saveLabel: "Simpan Budget",
      ),
    );
  }

  // ── Helper: Bottom Sheet template ───────────────────────────────────
  Widget _bottomSheet({
    required BuildContext ctx,
    required String title,
    required Color color,
    required List<Widget> children,
    required Future<void> Function() onSave,
    required String saveLabel,
  }) {
    bool isSaving = false;
    return StatefulBuilder(
      builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 16),
              // Tombol simpan
              SizedBox(
                width: double.infinity,
                height: 46,
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
                          } catch (e) {
                            _showError("Gagal: $e");
                          } finally {
                            if (ctx.mounted) {
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
                      : Text(saveLabel, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: Dropdown ────────────────────────────────────────────────
  Widget _dropdown(
    String label,
    List<dynamic> items,
    Function(int?) onChanged,
  ) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'],
          child: Text(item['name'] ?? item['description'] ?? ''),
        );
      }).toList(),
      onChanged: (v) => onChanged(v),
    );
  }

  // ── Helper: Input field ─────────────────────────────────────────────
  Widget _inputField(
    TextEditingController ctrl,
    String label, {
    bool isNumber = false,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  // ── BUILD ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rekap ${widget.title}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.attach_money), text: "Income"),
            Tab(icon: Icon(Icons.credit_card), text: "Hutang"),
            Tab(icon: Icon(Icons.pie_chart), text: "Budget"),
            Tab(icon: Icon(Icons.summarize), text: "Summary"),
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
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final report = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildIncomeTab(report),
              _buildDebtTab(report),
              _buildBudgetTab(report),
              _buildSummaryTab(report),
            ],
          );
        },
      ),
    );
  }

  // ── TAB 1: INCOME ────────────────────────────────────────────────────
  Widget _buildIncomeTab(Map<String, dynamic> report) {
    final incomeEntries = (report['income_entries'] as List?) ?? [];
    final businessIncomes = (report['business_incomes'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tombol tambah
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.green),
                  label: const Text(
                    "Tambah Income",
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: _showAddIncomeDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.business, color: Colors.blue),
                  label: const Text(
                    "Income Bisnis",
                    style: TextStyle(color: Colors.blue),
                  ),
                  onPressed: _showAddBusinessIncomeDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daftar income umum
          if (incomeEntries.isNotEmpty) ...[
            _sectionHeader("Pemasukan Umum", Colors.green),
            const SizedBox(height: 8),
            ...incomeEntries.map(
              (e) => _incomeCard(
                title: e['income_source']?['name'] ?? 'Income',
                subtitle: e['received_date'] ?? '',
                amount: e['amount'],
                color: Colors.green,
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Daftar income bisnis
          if (businessIncomes.isNotEmpty) ...[
            _sectionHeader("Income Bisnis", Colors.blue),
            const SizedBox(height: 8),
            ...businessIncomes.map(
              (e) => _incomeCard(
                title: e['description'] ?? '',
                subtitle: e['business']?['name'] ?? '',
                amount: e['amount'],
                color: Colors.blue,
                icon: Icons.business,
              ),
            ),
          ],

          if (incomeEntries.isEmpty && businessIncomes.isEmpty)
            _emptyState(
              "Belum ada pemasukan.\nTekan tombol di atas untuk menambah.",
            ),
        ],
      ),
    );
  }

  // ── TAB 2: HUTANG ────────────────────────────────────────────────────
  Widget _buildDebtTab(Map<String, dynamic> report) {
    final debts = (report['debts'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2 tombol: tambah hutang + bayar cicilan
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.orange),
                  label: const Text(
                    "Tambah Hutang",
                    style: TextStyle(color: Colors.orange),
                  ),
                  onPressed: _showAddDebtDialog,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.payment, color: Colors.red),
                  label: const Text(
                    "Bayar Cicilan",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: _showPayDebtDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (debts.isEmpty)
            _emptyState("Belum ada hutang tercatat.")
          else ...[
            _sectionHeader("Daftar Hutang Aktif", Colors.orange),
            const SizedBox(height: 8),
            ...debts.map(
              (debt) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.credit_card, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              debt['creditor_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatRupiah(debt['total_amount']),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Progress bar sisa cicilan
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: debt['total_months'] > 0
                              ? (debt['total_months'] -
                                        (debt['remaining_months'] ?? 0)) /
                                    debt['total_months']
                              : 0,
                          backgroundColor: Colors.orange.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.orange,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Cicilan: ${_formatRupiah(debt['monthly_installment'])}/bln — "
                        "Sisa ${debt['remaining_months'] ?? 0} bulan",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 3: BUDGET ────────────────────────────────────────────────────
  Widget _buildBudgetTab(Map<String, dynamic> report) {
    final budgets = (report['budget_allocations'] as List?) ?? [];

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
                "Tambah Alokasi Budget",
                style: TextStyle(color: Colors.purple),
              ),
              onPressed: _showAddBudgetDialog,
            ),
          ),
          const SizedBox(height: 16),

          if (budgets.isEmpty)
            _emptyState(
              "Belum ada alokasi budget.\nTekan tombol di atas untuk menambah.",
            )
          else ...[
            _sectionHeader("Alokasi Budget Bulan Ini", Colors.purple),
            const SizedBox(height: 8),

            // Total budget
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
                    "Total Budget",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatRupiah(
                      budgets.fold(
                        0.0,
                        (sum, b) =>
                            sum +
                            (double.tryParse(b['planned_amount'].toString()) ??
                                0),
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            ...budgets.map(
              (b) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade50,
                    child: const Icon(
                      Icons.pie_chart,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  title: Text(b['budget_category']?['name'] ?? 'Budget'),
                  subtitle:
                      b['notes'] != null && b['notes'].toString().isNotEmpty
                      ? Text(b['notes'])
                      : null,
                  trailing: Text(
                    _formatRupiah(b['planned_amount']),
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TAB 4: SUMMARY ───────────────────────────────────────────────────
  Widget _buildSummaryTab(Map<String, dynamic> report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Kartu saldo utama
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
                  "Saldo Akhir Rekap",
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

          // Kartu ringkasan
          _summaryCard(
            "Total Pemasukan",
            _formatRupiah(report['total_income'] ?? 0),
            Colors.green,
            Icons.arrow_downward,
          ),
          _summaryCard(
            "Total Pengeluaran",
            _formatRupiah(report['total_expense'] ?? 0),
            Colors.red,
            Icons.arrow_upward,
          ),
          _summaryCard(
            "Total Hutang Aktif",
            _formatRupiah(report['total_debt'] ?? 0),
            Colors.orange,
            Icons.credit_card,
          ),
          _summaryCard(
            "Total Budget",
            _formatRupiah(report['total_budget'] ?? 0),
            Colors.purple,
            Icons.pie_chart,
          ),

          const SizedBox(height: 16),

          // Tombol Lihat Laporan Lengkap
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
                "Lihat Laporan Lengkap",
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

          // Status & tombol finalisasi
          if (report['status'] != 'finalized')
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
                  "Finalisasi Rekap",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Finalisasi Rekap"),
                      content: const Text(
                        "Setelah difinalisasi, rekap tidak bisa diubah lagi. Lanjutkan?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Finalisasi"),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ApiService.finalizeRecap(widget.recapId);
                    _loadReport();
                    if (!mounted) return;
                    _showSuccess("Rekap berhasil difinalisasi!");
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
                    "Rekap sudah difinalisasi",
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

  // ── Helper Widgets ───────────────────────────────────────────────────
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

  Widget _incomeCard({
    required String title,
    required String subtitle,
    required dynamic amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: Text(
          _formatRupiah(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
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
}
