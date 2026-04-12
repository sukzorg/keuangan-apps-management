import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'recap_form_page.dart';
import 'recap_detail_page.dart';

class RecapListPage extends StatefulWidget {
  const RecapListPage({super.key});

  @override
  State<RecapListPage> createState() => _RecapListPageState();
}

class _RecapListPageState extends State<RecapListPage> {
  late Future<List<dynamic>> _recaps;

  final List<String> _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _recaps = ApiService.getMonthlyRecaps();
  }

  void _refresh() {
    setState(() => _recaps = ApiService.getMonthlyRecaps());
  }

  String _formatRupiah(dynamic value) {
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return "Rp ${(num / 1000000).toStringAsFixed(1)} Jt";
    if (num >= 1000) return "Rp ${(num / 1000).toStringAsFixed(0)} Rb";
    return "Rp ${num.toStringAsFixed(0)}";
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'finalized':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'finalized':
        return 'Final';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rekap Bulanan"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _recaps,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum ada rekap bulanan",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tekan + untuk membuat rekap bulan ini",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Buat Rekap Sekarang"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecapFormPage(),
                        ),
                      ).then((_) => _refresh());
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final recap = data[index];
              final month = int.tryParse(recap['month'].toString()) ?? 0;
              final year = recap['year'].toString();
              final status = recap['status'] ?? 'draft';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecapDetailPage(
                          recapId: recap['id'],
                          title: "${_monthNames[month]} $year",
                        ),
                      ),
                    ).then((_) => _refresh());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${_monthNames[month]} $year",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (recap['notes'] != null &&
                                      recap['notes'].toString().isNotEmpty)
                                    Text(
                                      recap['notes'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                // FIX: ganti withOpacity → withValues
                                color: _statusColor(
                                  status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor(status),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _summaryItem(
                                label: "Pemasukan",
                                value: _formatRupiah(
                                  recap['total_income'] ?? 0,
                                ),
                                color: Colors.green,
                                icon: Icons.arrow_downward,
                              ),
                            ),
                            Expanded(
                              child: _summaryItem(
                                label: "Pengeluaran",
                                value: _formatRupiah(
                                  recap['total_expense'] ?? 0,
                                ),
                                color: Colors.red,
                                icon: Icons.arrow_upward,
                              ),
                            ),
                            Expanded(
                              child: _summaryItem(
                                label: "Saldo",
                                value: _formatRupiah(
                                  recap['ending_balance'] ?? 0,
                                ),
                                color: Colors.indigo,
                                icon: Icons.account_balance_wallet,
                              ),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text("Lihat Detail"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecapDetailPage(
                                      recapId: recap['id'],
                                      title: "${_monthNames[month]} $year",
                                    ),
                                  ),
                                ).then((_) => _refresh());
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Rekap Baru", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecapFormPage()),
          ).then((_) => _refresh());
        },
      ),
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
