import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class GetAllDues {
  final DueRepository repository;

  GetAllDues({required this.repository});

  Future<List<MonthlyDue>> call() async {
    final result = await repository.getDues();
    if (result.isEmpty) {
      return [];
    }

    final map = <String, MonthlyDue>{};

    for (final currentDue in result) {
      final key = _getMonthYear(currentDue);
      map.putIfAbsent(key, () => MonthlyDue(month: key, dues: []));
      map[key]!.dues.add(
        Due(
          id: currentDue.id ?? 0,
          loanId: currentDue.loanId,
          name: currentDue.name,
          price: currentDue.amount,
          paid: currentDue.paid,
          installmentIndex: currentDue.installmentIndex,
          installmentCount: currentDue.installmentCount,
          dueDate: currentDue.dueDate,
          dayOfMonth: currentDue.dayOfMonth,
          recurring: currentDue.recurring,
          recurringInterval: currentDue.recurringInterval,
          complete: currentDue.complete,
          createdAt: currentDue.createdAt,
          updatedAt: currentDue.updatedAt,
        ),
      );
    }

    return map.values.toList();
  }

  DateTime _effectiveDate(DueEntity due) {
    if (due.dueDate != null && due.dueDate!.isNotEmpty) {
      return DateTime.tryParse(due.dueDate!) ?? DateTime.now();
    }
    if (due.createdAt != null && due.createdAt!.isNotEmpty) {
      return DateTime.tryParse(due.createdAt!) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _getMonthYear(DueEntity due) {
    const months = [
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
    final effectiveDate = _effectiveDate(due);
    return '${months[effectiveDate.month]} ${effectiveDate.year}';
  }
}

class MonthlyDue {
  String month;
  List<Due> dues;

  MonthlyDue({required this.month, required this.dues});
}

class Due {
  int id;
  String? loanId;
  String name;
  double price;
  bool paid;
  int? installmentIndex;
  int? installmentCount;
  String? dueDate;
  int dayOfMonth;
  bool recurring;
  int recurringInterval;
  bool complete;
  String? createdAt;
  String? updatedAt;

  Due({
    required this.id,
    required this.name,
    required this.price,
    required this.paid,
    required this.dayOfMonth,
    this.loanId,
    this.installmentIndex,
    this.installmentCount,
    this.dueDate,
    this.recurring = false,
    this.recurringInterval = 1,
    this.complete = false,
    this.createdAt,
    this.updatedAt,
  });

  DueEntity toEntity() {
    return DueEntity(
      id: id,
      name: name,
      amount: price,
      recurring: recurring,
      recurringInterval: recurringInterval,
      dayOfMonth: dayOfMonth,
      loanId: loanId,
      installmentIndex: installmentIndex,
      installmentCount: installmentCount,
      dueDate: dueDate,
      paid: paid,
      complete: complete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
