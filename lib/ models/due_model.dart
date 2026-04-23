class DueModel {
  int id;
  String name;
  double amount;
  bool recurring = false;
  int recurringInterval = 1;
  int dayOfMonth;
  bool paid = false;
  bool complete = false;
  String createdAt;
  String updatedAt;

  DueModel({
    required this.id,
    required this.name,
    required this.amount,
    this.recurring = false,
    this.recurringInterval = 1,
    required this.dayOfMonth,
    this.paid = false,
    this.complete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DueModel.fromMap(Map<String, dynamic> map) {
    return DueModel(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      recurring: map['recurring'] == 1,
      recurringInterval: map['recurring_interval'],
      dayOfMonth: map['day_of_month'],
      paid: map['paid'] == 1,
      complete: map['complete'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'recurring': recurring ? 1 : 0,
      'recurring_interval': recurringInterval,
      'day_of_month': dayOfMonth,
      'paid': paid ? 1 : 0,
      'complete': complete ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  
}
