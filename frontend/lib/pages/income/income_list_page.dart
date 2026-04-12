import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/income.dart';
import 'add_income_page.dart';
import 'edit_income_page.dart';

class IncomeListPage extends StatefulWidget {
  const IncomeListPage({super.key});

  @override
  State<IncomeListPage> createState() => _IncomeListPageState();
}

class _IncomeListPageState extends State<IncomeListPage> {
  late Future<List<Income>> incomes;

  @override
  void initState() {
    super.initState();
    incomes = ApiService.getIncomes();
  }

  void _refresh() {
    setState(() => incomes = ApiService.getIncomes());
  }

  // FIX: tambah curly braces di if/else
  String _formatRupiah(double amount) {
    if (amount >= 1000000) {
      return "Rp ${(amount / 1000000).toStringAsFixed(1)} Jt";
    } else if (amount >= 1000) {
      return "Rp ${(amount / 1000).toStringAsFixed(0)} Rb";
    } else {
      return "Rp ${amount.toStringAsFixed(0)}";
    }
  }

  Future<void> _deleteIncome(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Pemasukan"),
        content: const Text("Yakin ingin menghapus data ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteIncome(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pemasukan"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Income>>(
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  Text("Error: ${snapshot.error}"),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text("Coba lagi"),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_money, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "Belum ada pemasukan",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    "Tekan + untuk menambahkan",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
                      "Total Pemasukan",
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
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final income = data[index];
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          income.incomeSource == null
                              ? income.date
                              : '${income.incomeSource} • ${income.date}',
                        ),
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
                              builder: (_) => EditIncomePage(income: income),
                            ),
                          ).then((_) => _refresh());
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomePage()),
          ).then((_) => _refresh());
        },
      ),
    );
  }
}
