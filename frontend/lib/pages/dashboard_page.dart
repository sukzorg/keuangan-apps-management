import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import 'expense/expense_list_page.dart'; // ← path baru

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> _dashboard;
  late Future<List<Expense>> _expenses;

  final List<Color> _pieColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _dashboard = ApiService.getDashboard();
    _expenses = ApiService.getExpenses();
  }

  // Kelompokkan expense berdasarkan kategori
  Map<String, double> _groupByCategory(List<Expense> data) {
    final Map<String, double> result = {};
    for (final e in data) {
      result[e.category] = (result[e.category] ?? 0) + e.amount;
    }
    return result;
  }

  // Format angka ke Rupiah singkat: 8000000 → 8 Jt
  String _formatRupiah(dynamic value) {
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) {
      return "Rp ${(num / 1000000).toStringAsFixed(1)} Jt";
    } else if (num >= 1000) {
      return "Rp ${(num / 1000).toStringAsFixed(0)} Rb";
    }
    return "Rp ${num.toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Kartu Saldo ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.blueAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Saldo Saat Ini",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatRupiah(data['balance']),
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

                // ── Income & Expense ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.arrow_downward,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Pemasukan",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatRupiah(data['total_income']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.arrow_upward,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Pengeluaran",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatRupiah(data['total_expense']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── PieChart dari data REAL ───────────────────────
                const Text(
                  "Distribusi Pengeluaran",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                FutureBuilder<List<Expense>>(
                  future: _expenses,
                  builder: (context, expSnap) {
                    if (expSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!expSnap.hasData || expSnap.data!.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text("Belum ada data pengeluaran"),
                          ),
                        ),
                      );
                    }

                    final grouped = _groupByCategory(expSnap.data!);
                    final entries = grouped.entries.toList();
                    final total = grouped.values.fold(0.0, (a, b) => a + b);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: List.generate(entries.length, (i) {
                                    final pct =
                                        (entries[i].value / total) * 100;
                                    return PieChartSectionData(
                                      value: entries[i].value,
                                      title: "${pct.toStringAsFixed(0)}%",
                                      color: _pieColors[i % _pieColors.length],
                                      radius: 70,
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Legend
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: List.generate(entries.length, (i) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color:
                                            _pieColors[i % _pieColors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      entries[i].key,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── Tombol Lihat Transaksi ────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text("Lihat Semua Transaksi"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExpenseListPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
