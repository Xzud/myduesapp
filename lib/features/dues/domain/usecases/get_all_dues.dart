import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';

class GetAllDues {
  final DueRepository repository;

  GetAllDues({required this.repository});

  Future<List<MonthlyDue>> call() async {
    final result = await repository.getDues();

    List<MonthlyDue> dues = [];

    if (result.isEmpty) {
      print('No dues found');
      return [];
    }

    for (var currentDue in result) {
      // TODO next step add day as to tell which billing period to settle
      if (dues.isEmpty) {
        dues.add(
          MonthlyDue(
            month: currentDue.getMonthYear(),
            dues: [
              Due(
                name: currentDue.name,
                price: currentDue.amount,
                paid: currentDue.paid,
              ),
            ],
          ),
        );
        continue;
      } else {
        for (var due in dues) {
          if (due.month == currentDue.getMonthYear()) {
            due.dues.add(
              Due(
                name: currentDue.name,
                price: currentDue.amount,
                paid: currentDue.paid,
              ),
            );
            break;
          } else {
            dues.add(
              MonthlyDue(
                month: currentDue.getMonthYear(),
                dues: [
                  Due(
                    name: currentDue.name,
                    price: currentDue.amount,
                    paid: currentDue.paid,
                  ),
                ],
              ),
            );
            break;
          }
        }
      }
    }

    return dues;
  }
}

class MonthlyDue {
  String month;
  List<Due> dues;

  MonthlyDue({required this.month, required this.dues});
}

class Due {
  String name;
  double price;
  bool paid;

  Due({required this.name, required this.price, required this.paid});
}
