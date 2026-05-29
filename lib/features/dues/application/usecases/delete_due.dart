import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class DeleteDue {
  final DueRepository repository;

  DeleteDue({required this.repository});

  Future<void> call(int id) async {
    await repository.deleteDue(id);
  }
}
