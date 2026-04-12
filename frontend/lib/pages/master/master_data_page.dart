import 'package:flutter/material.dart';

import '../../models/master_record.dart';
import '../../services/api_service.dart';

enum MasterDataModule {
  paymentMethods,
  categories,
  budgetCategories,
  debtCategories,
  incomeSources,
  businessProfiles,
  businessExpenseCategories,
}

extension MasterDataModuleX on MasterDataModule {
  String get resource {
    switch (this) {
      case MasterDataModule.paymentMethods:
        return 'payment-methods';
      case MasterDataModule.categories:
        return 'categories';
      case MasterDataModule.budgetCategories:
        return 'budget-categories';
      case MasterDataModule.debtCategories:
        return 'debt-categories';
      case MasterDataModule.incomeSources:
        return 'income-sources';
      case MasterDataModule.businessProfiles:
        return 'business-profiles';
      case MasterDataModule.businessExpenseCategories:
        return 'business-expense-categories';
    }
  }

  String get title {
    switch (this) {
      case MasterDataModule.paymentMethods:
        return 'Metode Pembayaran';
      case MasterDataModule.categories:
        return 'Kategori Transaksi';
      case MasterDataModule.budgetCategories:
        return 'Kategori Anggaran';
      case MasterDataModule.debtCategories:
        return 'Kategori Utang';
      case MasterDataModule.incomeSources:
        return 'Sumber Pemasukan';
      case MasterDataModule.businessProfiles:
        return 'Profil Bisnis';
      case MasterDataModule.businessExpenseCategories:
        return 'Kategori Pengeluaran Bisnis';
    }
  }

  String get description {
    switch (this) {
      case MasterDataModule.paymentMethods:
        return 'Kelola rekening, dompet digital, dan metode pembayaran yang digunakan pada transaksi.';
      case MasterDataModule.categories:
        return 'Kelola kategori pengeluaran untuk transaksi harian.';
      case MasterDataModule.budgetCategories:
        return 'Kelola kelompok anggaran berdasarkan prioritas kebutuhan.';
      case MasterDataModule.debtCategories:
        return 'Kelola jenis utang atau pinjaman yang dicatat di aplikasi.';
      case MasterDataModule.incomeSources:
        return 'Kelola sumber pemasukan seperti gaji, bisnis, investasi, dan lainnya.';
      case MasterDataModule.businessProfiles:
        return 'Kelola daftar unit usaha atau bisnis yang menjadi sumber pemasukan.';
      case MasterDataModule.businessExpenseCategories:
        return 'Kelola kategori pengeluaran yang spesifik untuk masing-masing bisnis.';
    }
  }

  bool get supportsStatus => true;
}

class MasterDataPage extends StatefulWidget {
  const MasterDataPage({super.key});

  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  MasterDataModule _selectedModule = MasterDataModule.paymentMethods;
  List<MasterRecord> _records = const [];
  List<MasterRecord> _businesses = const [];
  int? _selectedBusinessId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _loadBusinesses();
    await _loadRecords();
  }

  Future<void> _loadBusinesses() async {
    try {
      final businesses = await ApiService.getMasterData('business-profiles');
      setState(() {
        _businesses = businesses;
        _selectedBusinessId ??= businesses.isNotEmpty
            ? businesses.first.id
            : null;
      });
    } catch (_) {
      setState(() {
        _businesses = const [];
        _selectedBusinessId = null;
      });
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await ApiService.getMasterData(
        _selectedModule.resource,
        businessId:
            _selectedModule == MasterDataModule.businessExpenseCategories
            ? _selectedBusinessId
            : null,
        type: _selectedModule == MasterDataModule.categories ? 'expense' : null,
      );

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _records = const [];
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(MasterRecord record, bool value) async {
    try {
      await ApiService.updateMasterData(_selectedModule.resource, record.id, {
        'is_active': value,
      });
      await _loadRecords();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _openForm({MasterRecord? record}) async {
    if (_selectedModule == MasterDataModule.businessExpenseCategories &&
        _businesses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tambahkan profil bisnis terlebih dahulu sebelum membuat kategori pengeluaran bisnis.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: record?.name ?? '');
    final descriptionController = TextEditingController(
      text: record?.description ?? '',
    );
    final accountNumberController = TextEditingController(
      text: record?.accountNumber ?? '',
    );
    final accountNameController = TextEditingController(
      text: record?.accountName ?? '',
    );

    String? selectedType = record?.type;
    String? selectedPriority = record?.priority;
    int? selectedBusinessId = record?.businessId ?? _selectedBusinessId;
    bool isActive = record?.isActive ?? true;
    bool isSaving = false;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveForm() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final payload = <String, dynamic>{
                'name': nameController.text.trim(),
                'is_active': isActive,
              };

              final description = descriptionController.text.trim();
              final accountNumber = accountNumberController.text.trim();
              final accountName = accountNameController.text.trim();

              switch (_selectedModule) {
                case MasterDataModule.paymentMethods:
                  payload['type'] = selectedType;
                  payload['account_number'] = accountNumber.isEmpty
                      ? null
                      : accountNumber;
                  payload['account_name'] = accountName.isEmpty
                      ? null
                      : accountName;
                  break;
                case MasterDataModule.categories:
                  payload['type'] = 'expense';
                  break;
                case MasterDataModule.budgetCategories:
                  payload['priority'] = selectedPriority;
                  payload['description'] = description.isEmpty
                      ? null
                      : description;
                  break;
                case MasterDataModule.debtCategories:
                  payload['description'] = description.isEmpty
                      ? null
                      : description;
                  break;
                case MasterDataModule.incomeSources:
                  payload['type'] = selectedType;
                  payload['business_id'] = selectedType == 'business'
                      ? selectedBusinessId
                      : null;
                  payload['description'] = description.isEmpty
                      ? null
                      : description;
                  break;
                case MasterDataModule.businessProfiles:
                  payload['type'] = selectedType;
                  payload['description'] = description.isEmpty
                      ? null
                      : description;
                  break;
                case MasterDataModule.businessExpenseCategories:
                  payload['business_id'] = selectedBusinessId;
                  payload['description'] = description.isEmpty
                      ? null
                      : description;
                  break;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                if (record == null) {
                  await ApiService.createMasterData(
                    _selectedModule.resource,
                    payload,
                  );
                } else {
                  await ApiService.updateMasterData(
                    _selectedModule.resource,
                    record.id,
                    payload,
                  );
                }

                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                await _loadBusinesses();
                await _loadRecords();
              } catch (error) {
                setDialogState(() {
                  isSaving = false;
                });

                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            }

            return AlertDialog(
              title: Text(
                record == null
                    ? 'Tambah ${_selectedModule.title}'
                    : 'Ubah ${_selectedModule.title}',
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Nama'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_needsTypeField(_selectedModule))
                          Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Jenis',
                                ),
                                items: _typeOptions(_selectedModule).entries
                                    .map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedType = value;
                                    if (value != 'business' &&
                                        _selectedModule ==
                                            MasterDataModule.incomeSources) {
                                      selectedBusinessId = null;
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Jenis wajib dipilih';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        if (_selectedModule ==
                            MasterDataModule.budgetCategories)
                          Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: selectedPriority,
                                decoration: const InputDecoration(
                                  labelText: 'Prioritas',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'wajib',
                                    child: Text('Wajib'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'penting',
                                    child: Text('Penting'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'keinginan',
                                    child: Text('Keinginan'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedPriority = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Prioritas wajib dipilih';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        if (_needsBusinessField(_selectedModule, selectedType))
                          Column(
                            children: [
                              DropdownButtonFormField<int>(
                                initialValue: selectedBusinessId,
                                decoration: const InputDecoration(
                                  labelText: 'Profil Bisnis',
                                ),
                                items: _businesses
                                    .map(
                                      (business) => DropdownMenuItem(
                                        value: business.id,
                                        child: Text(business.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedBusinessId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Profil bisnis wajib dipilih';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        if (_needsDescriptionField(_selectedModule))
                          Column(
                            children: [
                              TextFormField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Deskripsi',
                                ),
                                minLines: 2,
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        if (_selectedModule == MasterDataModule.paymentMethods)
                          Column(
                            children: [
                              TextFormField(
                                controller: accountNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor Akun',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: accountNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Pemilik Akun',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Status Aktif'),
                          value: isActive,
                          onChanged: (value) {
                            setDialogState(() {
                              isActive = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : saveForm,
                  child: Text(isSaving ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _needsTypeField(MasterDataModule module) {
    return module == MasterDataModule.paymentMethods ||
        module == MasterDataModule.incomeSources ||
        module == MasterDataModule.businessProfiles;
  }

  bool _needsDescriptionField(MasterDataModule module) {
    return module == MasterDataModule.budgetCategories ||
        module == MasterDataModule.debtCategories ||
        module == MasterDataModule.incomeSources ||
        module == MasterDataModule.businessProfiles ||
        module == MasterDataModule.businessExpenseCategories;
  }

  bool _needsBusinessField(MasterDataModule module, String? selectedType) {
    return module == MasterDataModule.businessExpenseCategories ||
        (module == MasterDataModule.incomeSources &&
            selectedType == 'business');
  }

  Map<String, String> _typeOptions(MasterDataModule module) {
    switch (module) {
      case MasterDataModule.paymentMethods:
        return const {
          'cash': 'Tunai',
          'e_wallet': 'Dompet Digital',
          'bank_transfer': 'Transfer Bank',
        };
      case MasterDataModule.categories:
        return const {'expense': 'Pengeluaran'};
      case MasterDataModule.incomeSources:
        return const {
          'salary': 'Gaji',
          'business': 'Bisnis',
          'investment': 'Investasi',
          'other': 'Lainnya',
        };
      case MasterDataModule.businessProfiles:
        return const {
          'photography': 'Fotografi',
          'service_gadget': 'Servis Gadget',
          'internet_provider': 'Internet RT/RW',
          'boarding_house': 'Kosan',
          'app_development': 'Jasa Aplikasi',
          'other': 'Lainnya',
        };
      case MasterDataModule.budgetCategories:
      case MasterDataModule.debtCategories:
      case MasterDataModule.businessExpenseCategories:
        return const {};
    }
  }

  String _buildSubtitle(MasterRecord record) {
    final parts = <String>[];

    switch (_selectedModule) {
      case MasterDataModule.paymentMethods:
        if (record.type != null) {
          parts.add(_typeOptions(_selectedModule)[record.type] ?? record.type!);
        }
        if (record.accountNumber != null && record.accountNumber!.isNotEmpty) {
          parts.add('No. akun: ${record.accountNumber}');
        }
        if (record.accountName != null && record.accountName!.isNotEmpty) {
          parts.add(record.accountName!);
        }
        break;
      case MasterDataModule.categories:
        parts.add('Pengeluaran');
        break;
      case MasterDataModule.budgetCategories:
        if (record.priority != null) {
          parts.add('Prioritas ${record.priority}');
        }
        if (record.description != null && record.description!.isNotEmpty) {
          parts.add(record.description!);
        }
        break;
      case MasterDataModule.debtCategories:
        if (record.description != null && record.description!.isNotEmpty) {
          parts.add(record.description!);
        }
        break;
      case MasterDataModule.incomeSources:
        if (record.type != null) {
          parts.add(_typeOptions(_selectedModule)[record.type] ?? record.type!);
        }
        if (record.businessName != null) {
          parts.add(record.businessName!);
        }
        if (record.description != null && record.description!.isNotEmpty) {
          parts.add(record.description!);
        }
        break;
      case MasterDataModule.businessProfiles:
        if (record.type != null) {
          parts.add(_typeOptions(_selectedModule)[record.type] ?? record.type!);
        }
        if (record.description != null && record.description!.isNotEmpty) {
          parts.add(record.description!);
        }
        break;
      case MasterDataModule.businessExpenseCategories:
        if (record.businessName != null) {
          parts.add(record.businessName!);
        }
        if (record.description != null && record.description!.isNotEmpty) {
          parts.add(record.description!);
        }
        break;
    }

    return parts.isEmpty ? 'Tidak ada deskripsi tambahan.' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<MasterDataModule>(
                          initialValue: _selectedModule,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Master Data',
                          ),
                          items: MasterDataModule.values
                              .map(
                                (module) => DropdownMenuItem(
                                  value: module,
                                  child: Text(module.title),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            setState(() {
                              _selectedModule = value;
                            });
                            await _loadRecords();
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedModule.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_selectedModule ==
                            MasterDataModule.businessExpenseCategories)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedBusinessId,
                              decoration: const InputDecoration(
                                labelText: 'Filter Profil Bisnis',
                              ),
                              items: _businesses
                                  .map(
                                    (business) => DropdownMenuItem(
                                      value: business.id,
                                      child: Text(business.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) async {
                                setState(() {
                                  _selectedBusinessId = value;
                                });
                                await _loadRecords();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRecords,
              child: _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text('Tambah ${_selectedModule.title}'),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_errorMessage!),
            ),
          ),
        ],
      );
    }

    if (_records.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Belum ada data untuk master data yang dipilih.'),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = _records[index];
        return Card(
          child: ListTile(
            title: Text(record.name),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_buildSubtitle(record)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedModule.supportsStatus)
                  Switch.adaptive(
                    value: record.isActive,
                    onChanged: (value) => _toggleStatus(record, value),
                  ),
                IconButton(
                  onPressed: () => _openForm(record: record),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Ubah data',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
