class Income {
  final int id;
  final int? categoryId;
  final String? category;
  final int? incomeSourceId;
  final String? incomeSource;
  final String name;
  final double amount;
  final String date;

  Income({
    required this.id,
    this.categoryId,
    this.category,
    this.incomeSourceId,
    this.incomeSource,
    required this.name,
    required this.amount,
    required this.date,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      categoryId: json['category_id'],
      category: json['category']?['name'],
      incomeSourceId: json['income_source_id'],
      incomeSource: json['income_source']?['name'],
      name: json['name'],
      amount: double.parse(json['amount'].toString()),
      date: json['date'],
    );
  }
}
