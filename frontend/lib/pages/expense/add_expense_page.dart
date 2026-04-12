import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/category.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.getCategories(type: 'expense');
      setState(() {
        _categories = data;
        if (_selectedCategory == null && data.isNotEmpty) {
          _selectedCategory = data.first;
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _errorMessage = "Gagal memuat kategori: $e";
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveExpense() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama pengeluaran tidak boleh kosong")),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah harus berupa angka")),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih kategori dulu")));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ApiService.addExpense(
        categoryId: _selectedCategory!.id,
        name: _nameController.text.trim(),
        amount: amount,
        date: _selectedDate.toString().substring(0, 10),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Pengeluaran"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Pengeluaran",
                hintText: "contoh: Makan siang, Bensin",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Jumlah (Rp)",
                hintText: "contoh: 50000",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown kategori
            if (_isLoadingCategories)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text("Memuat kategori..."),
                ],
              )
            else if (_errorMessage != null)
              Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Coba lagi"),
                    onPressed: () {
                      setState(() {
                        _isLoadingCategories = true;
                        _errorMessage = null;
                      });
                      _loadCategories();
                    },
                  ),
                ],
              )
            else if (_categories.isEmpty)
              const Text(
                "Tidak ada kategori tersedia.",
                style: TextStyle(color: Colors.orange),
              )
            else
              // FIX: ganti value → initialValue
              DropdownButtonFormField<Category>(
                decoration: const InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                hint: const Text("Pilih kategori"),
                initialValue: _selectedCategory,
                items: _categories.map((cat) {
                  return DropdownMenuItem<Category>(
                    value: cat,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),

            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tanggal",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _selectedDate.toString().substring(0, 10),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _saveExpense,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Simpan", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
