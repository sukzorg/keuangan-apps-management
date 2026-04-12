import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RecapFormPage extends StatefulWidget {
  const RecapFormPage({super.key});

  @override
  State<RecapFormPage> createState() => _RecapFormPageState();
}

class _RecapFormPageState extends State<RecapFormPage> {
  final _notesController = TextEditingController();
  bool _isLoading = false;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

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
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createRecap() async {
    setState(() => _isLoading = true);
    try {
      final recapDate =
          "$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-25";

      await ApiService.createMonthlyRecap(
        _selectedYear,
        _selectedMonth,
        recapDate,
        _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Rekap ${_monthNames[_selectedMonth]} $_selectedYear berhasil dibuat!",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      // Pesan error lebih informatif
      String errorMsg = e.toString();
      if (errorMsg.contains('duplicate') || errorMsg.contains('422')) {
        errorMsg =
            "Rekap ${_monthNames[_selectedMonth]} $_selectedYear sudah ada!";
      } else if (errorMsg.contains('connection')) {
        errorMsg = "Tidak bisa konek ke server. Pastikan Laravel berjalan.";
      } else {
        errorMsg = "Gagal membuat rekap. Coba lagi.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Rekap Baru"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      // FIX OVERFLOW: pakai SingleChildScrollView + resizeToAvoidBottomInset
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          // FIX: tambah padding bawah saat keyboard muncul
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Rekap bulanan mencatat semua pemasukan, pengeluaran bisnis, hutang, dan budget dalam satu periode.",
                      style: TextStyle(fontSize: 13, color: Colors.indigo),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pilih Bulan
            const Text(
              "Bulan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              items: List.generate(12, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: Text(_monthNames[i + 1]),
                );
              }),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMonth = val);
              },
            ),

            const SizedBox(height: 16),

            // Pilih Tahun
            const Text(
              "Tahun",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              items: [2024, 2025, 2026, 2027].map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedYear = val);
              },
            ),

            const SizedBox(height: 16),

            // Catatan
            const Text(
              "Catatan (opsional)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "contoh: Bulan ini ada pengeluaran ekstra...",
              ),
            ),

            const SizedBox(height: 24),

            // Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Rekap yang akan dibuat:",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        "${_monthNames[_selectedMonth]} $_selectedYear",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tombol buat
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isLoading ? "Membuat..." : "Buat Rekap",
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: _isLoading ? null : _createRecap,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
