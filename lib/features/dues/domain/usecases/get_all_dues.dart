import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';

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
      final key = currentDue.getMonthYear();
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
        ),
      );
    }

    return map.values.toList();
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

  Due({
    required this.id,
    required this.name,
    required this.price,
    required this.paid,
    this.loanId,
    this.installmentIndex,
    this.installmentCount,
    this.dueDate,
  });
}
