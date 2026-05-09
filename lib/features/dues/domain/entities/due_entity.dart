class DueEntity {
  int? id;
  String name;
  double amount;
  bool recurring;
  int recurringInterval;
  int dayOfMonth;
  bool paid;
  bool complete;
  String? createdAt;
  String? updatedAt;

  DueEntity({
    this.id,
    required this.name,
    required this.amount,
    this.recurring = false,
    this.recurringInterval = 1,
    required this.dayOfMonth,
    this.paid = false,
    this.complete = false,
    this.createdAt,
    this.updatedAt,
  });
}
