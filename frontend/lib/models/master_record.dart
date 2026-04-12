class MasterRecord {
  final int id;
  final String name;
  final String? description;
  final String? type;
  final String? priority;
  final int? businessId;
  final String? businessName;
  final String? accountNumber;
  final String? accountName;
  final bool isActive;
  final Map<String, dynamic> raw;

  const MasterRecord({
    required this.id,
    required this.name,
    required this.isActive,
    required this.raw,
    this.description,
    this.type,
    this.priority,
    this.businessId,
    this.businessName,
    this.accountNumber,
    this.accountName,
  });

  factory MasterRecord.fromJson(Map<String, dynamic> json) {
    final dynamic businessData = json['business'];

    return MasterRecord(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      type: json['type']?.toString(),
      priority: json['priority']?.toString(),
      businessId: json['business_id'] as int?,
      businessName: businessData is Map<String, dynamic>
          ? businessData['name']?.toString()
          : null,
      accountNumber: json['account_number']?.toString(),
      accountName: json['account_name']?.toString(),
      isActive: json.containsKey('is_active')
          ? _parseBool(json['is_active'])
          : true,
      raw: json,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return false;
  }
}
