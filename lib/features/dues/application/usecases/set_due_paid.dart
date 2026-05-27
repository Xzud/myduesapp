import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class SetDuePaid {
  final DueRepository repository;

  SetDuePaid({required this.repository});

  Future<void> call(int id, bool paid) async {
    await repository.setPaid(id, paid);
  }
}
