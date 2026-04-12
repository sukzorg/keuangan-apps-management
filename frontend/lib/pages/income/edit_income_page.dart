import 'package:flutter/material.dart';

import '../../models/income.dart';
import '../../models/master_record.dart';
import '../../services/api_service.dart';

class EditIncomePage extends StatefulWidget {
  final Income income;

  const EditIncomePage({super.key, required this.income});

  @override
  State<EditIncomePage> createState() => _EditIncomePageState();
}

class _EditIncomePageState extends State<EditIncomePage> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  String? _categoryError;
  List<MasterRecord> _incomeSources = [];
  MasterRecord? _selectedIncomeSource;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.income.name);
    _amountController = TextEditingController(
      text: widget.income.amount.toStringAsFixed(0),
    );
    _selectedDate = DateTime.tryParse(widget.income.date) ?? DateTime.now();
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
      final data = await ApiService.getMasterData(
        'income-sources',
        includeInactive: false,
      );
      MasterRecord? selectedIncomeSource;

      if (widget.income.incomeSourceId != null) {
        for (final source in data) {
          if (source.id == widget.income.incomeSourceId) {
            selectedIncomeSource = source;
            break;
          }
        }
      }

      selectedIncomeSource ??= data.isNotEmpty ? data.first : null;

      setState(() {
        _incomeSources = data;
        _selectedIncomeSource = selectedIncomeSource;
        _isLoadingCategories = false;
        _categoryError = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoryError = "Gagal memuat kategori: $e";
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

  Future<void> _updateIncome() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah harus berupa angka")),
      );
      return;
    }

    if (_selectedIncomeSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih sumber pemasukan terlebih dahulu")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.updateIncome(
        id: widget.income.id,
        name: _nameController.text.trim(),
        amount: amount,
        date: _selectedDate.toString().substring(0, 10),
        incomeSourceId: _selectedIncomeSource!.id,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal update: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCategoryField() {
    if (_isLoadingCategories) {
      return const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text("Memuat sumber pemasukan..."),
        ],
      );
    }

    if (_categoryError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_categoryError!, style: const TextStyle(color: Colors.red)),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isLoadingCategories = true;
                _categoryError = null;
              });
              _loadCategories();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Coba lagi"),
          ),
        ],
      );
    }

    if (_incomeSources.isEmpty) {
      return const Text(
        "Belum ada sumber pemasukan tersedia.",
        style: TextStyle(color: Colors.orange),
      );
    }

    return DropdownButtonFormField<MasterRecord>(
      initialValue: _selectedIncomeSource,
      decoration: const InputDecoration(
        labelText: "Sumber Pemasukan",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.account_tree_outlined),
      ),
      items: _incomeSources
          .map(
            (source) => DropdownMenuItem<MasterRecord>(
              value: source,
              child: Text(source.name),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedIncomeSource = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Pemasukan"),
        backgroundColor: Colors.green,
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
                labelText: "Nama Pemasukan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Jumlah (Rp)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryField(),
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
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _updateIncome,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Update", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
