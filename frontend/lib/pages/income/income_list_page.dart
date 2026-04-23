import 'package:flutter/material.dart';

import '../../models/income.dart';
import '../../services/api_service.dart';
import 'add_income_page.dart';
import 'edit_income_page.dart';

class IncomeListPage extends StatefulWidget {
  const IncomeListPage({super.key});

  @override
  State<IncomeListPage> createState() => _IncomeListPageState();
}

class _IncomeListPageState extends State<IncomeListPage> {
  late Future<List<Income>> incomes;
  late DateTime _filterFrom;
  late DateTime _filterTo;
  bool _isCustomFilter = false;

  @override
  void initState() {
    super.initState();
    _resetToDefaultRange(refresh: false);
    _loadIncomes();
  }

  void _resetToDefaultRange({bool refresh = true}) {
    final now = DateTime.now();
    _filterTo = DateTime(now.year, now.month, now.day);
    _filterFrom = _filterTo.subtract(const Duration(days: 29));
    _isCustomFilter = false;

    if (refresh) {
      _loadIncomes();
    }
  }

  void _loadIncomes() {
    setState(() {
      incomes = ApiService.getIncomes(
        dateFrom: _formatApiDate(_filterFrom),
        dateTo: _formatApiDate(_filterTo),
      );
    });
  }

  Future<void> _refresh() async {
    _loadIncomes();
    await incomes;
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
      helpText: 'Filter Pemasukan',
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
    _loadIncomes();
  }

  Future<void> _deleteIncome(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pemasukan'),
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
      await ApiService.deleteIncome(id);
      _loadIncomes();
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCustomFilter
                      ? 'Filter aktif untuk menampilkan data di luar 30 hari terakhir.'
                      : 'Menampilkan data pemasukan 30 hari terakhir.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
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
        title: const Text('Pemasukan'),
        backgroundColor: Colors.green,
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
            child: FutureBuilder<List<Income>>(
              future: incomes,
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
                        Text('Error: ${snapshot.error}'),
                        TextButton(
                          onPressed: _loadIncomes,
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
                        Icon(Icons.attach_money, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Tidak ada pemasukan pada periode ini',
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
                      color: Colors.green.shade50,
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Total Pemasukan',
                            style: TextStyle(color: Colors.green),
                          ),
                          const Spacer(),
                          Text(
                            _formatRupiah(total),
                            style: const TextStyle(
                              color: Colors.green,
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
                            final income = data[index];
                            final subtitle = income.incomeSource == null
                                ? income.date
                                : '${income.incomeSource} • ${income.date}';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade100,
                                  child: const Icon(
                                    Icons.attach_money,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(
                                  income.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(subtitle),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatRupiah(income.amount),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteIncome(income.id),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditIncomePage(income: income),
                                    ),
                                  ).then((_) => _loadIncomes());
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
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomePage()),
          ).then((_) => _loadIncomes());
        },
      ),
    );
  }
}
