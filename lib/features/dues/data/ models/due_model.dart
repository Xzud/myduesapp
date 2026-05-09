import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';

class DueModel extends DueEntity {

  DueModel({
    super.id,
    required super.name,
    required super.amount,
    super.recurring = false,
    super.recurringInterval = 1,
    required super.dayOfMonth,
    super.paid = false,
    super.complete = false,
    super.createdAt,
    super.updatedAt,
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

  Map<String, dynamic> toMap(String? createdAt) {
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
      'updated_at': DateTime.now().toString(),
    };
  }

  void create(dynamic db) async {
    await db.insert('dues', toMap(createdAt));
  }

  void update(dynamic db) async {
    await db.update('dues', toMap(null));
  }

  void delete(dynamic db) async {
    await db.delete('dues', where: 'id = ?', whereArgs: [id]);
  }

  String getMonthYear() {
    List<String> months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    DateTime now = DateTime.parse(createdAt ?? DateTime.now().toString());
    String monthYear = "${months[now.month]} ${now.year}";
    return monthYear;
  }

  DueEntity toEntity() {
    return DueEntity(
      id: id,
      name: name,
      amount: amount,
      recurring: recurring,
      recurringInterval: recurringInterval,
      dayOfMonth: dayOfMonth,
      paid: paid,
      complete: complete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
