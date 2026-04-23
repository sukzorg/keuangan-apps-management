import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../services/api_service.dart';
import 'add_expense_page.dart';
import 'edit_expense_page.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  late Future<List<Expense>> expenses;
  late DateTime _filterFrom;
  late DateTime _filterTo;
  bool _isCustomFilter = false;

  @override
  void initState() {
    super.initState();
    _resetToDefaultRange(refresh: false);
    _loadExpenses();
  }

  void _resetToDefaultRange({bool refresh = true}) {
    final now = DateTime.now();
    _filterTo = DateTime(now.year, now.month, now.day);
    _filterFrom = _filterTo.subtract(const Duration(days: 29));
    _isCustomFilter = false;

    if (refresh) {
      _loadExpenses();
    }
  }

  void _loadExpenses() {
    setState(() {
      expenses = ApiService.getExpenses(
        dateFrom: _formatApiDate(_filterFrom),
        dateTo: _formatApiDate(_filterTo),
      );
    });
  }

  Future<void> _refresh() async {
    _loadExpenses();
    await expenses;
  }

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateLabel(DateTime date) {
    const monthNames = [
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

  String _formatRupiah(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)} Jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)} Rb';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  Future<void> _selectFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _filterFrom, end: _filterTo),
      helpText: 'Filter Pengeluaran',
      saveText: 'Terapkan',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _filterFrom = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _filterTo = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
      );
      _isCustomFilter = true;
    });
    _loadExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteExpense(id);
      _loadExpenses();
    }
  }

  Widget _buildFilterBanner() {
    final label =
        '${_formatDateLabel(_filterFrom)} - ${_formatDateLabel(_filterTo)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCustomFilter
                      ? 'Filter aktif untuk menampilkan data di luar 30 hari terakhir.'
                      : 'Menampilkan data pengeluaran 30 hari terakhir.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: Colors.black87)),
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
        title: const Text('Pengeluaran'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Filter tanggal',
            onPressed: _selectFilter,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
          if (_isCustomFilter)
            IconButton(
              tooltip: 'Reset 30 hari',
              onPressed: () => setState(() => _resetToDefaultRange()),
              icon: const Icon(Icons.restore),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBanner(),
          Expanded(
            child: FutureBuilder<List<Expense>>(
              future: expenses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Text('Error: ${snapshot.error}'),
                        TextButton(
                          onPressed: _loadExpenses,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Icon(Icons.money_off, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Tidak ada pengeluaran pada periode ini',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Gunakan filter untuk melihat data yang lebih lama.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final total = data.fold(0.0, (sum, e) => sum + e.amount);

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.red.shade50,
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Total Pengeluaran',
                            style: TextStyle(color: Colors.red),
                          ),
                          const Spacer(),
                          Text(
                            _formatRupiah(total),
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final expense = data[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: const Icon(
                                    Icons.money_off,
                                    color: Colors.red,
                                  ),
                                ),
                                title: Text(
                                  expense.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${expense.category} • ${expense.date}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatRupiah(expense.amount),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteExpense(expense.id),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditExpensePage(expense: expense),
                                    ),
                                  ).then((_) => _loadExpenses());
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          ).then((_) => _loadExpenses());
        },
      ),
    );
  }
}
