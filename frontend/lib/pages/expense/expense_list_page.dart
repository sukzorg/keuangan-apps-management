import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // ← naik 2 level
import '../../models/expense.dart'; // ← naik 2 level
import 'add_expense_page.dart'; // ← sama folder
import 'edit_expense_page.dart'; // ← sama folder

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  late Future<List<Expense>> expenses;

  @override
  void initState() {
    super.initState();
    expenses = ApiService.getExpenses();
  }

  void _refresh() {
    setState(() {
      expenses = ApiService.getExpenses();
    });
  }

  String _formatRupiah(double amount) {
    if (amount >= 1000000) {
      return "Rp ${(amount / 1000000).toStringAsFixed(1)} Jt";
    } else if (amount >= 1000) {
      return "Rp ${(amount / 1000).toStringAsFixed(0)} Rb";
    }
    return "Rp ${amount.toStringAsFixed(0)}";
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Pengeluaran"),
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
      await ApiService.deleteExpense(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengeluaran"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<List<Expense>>(
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
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
                  Icon(Icons.money_off, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "Belum ada pengeluaran",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 4),
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
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      "Total Pengeluaran",
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
                          child: const Icon(Icons.money_off, color: Colors.red),
                        ),
                        title: Text(
                          expense.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(expense.category),
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
                              builder: (_) => EditExpensePage(expense: expense),
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
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          ).then((_) => _refresh());
        },
      ),
    );
  }
}
