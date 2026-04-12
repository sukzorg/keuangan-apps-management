class Expense {
  final int id;
  final String name;
  final double amount;
  final String date;
  final String category;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      name: json['name'],
      amount: double.parse(json['amount'].toString()),
      date: json['date'],
      category: json['category']['name'],
    );
  }
}
