import 'package:myduesapp/features/dues/data/models/due_model.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';

class CreateDue {
  final DueRepository repository;

  CreateDue({required this.repository});

  Future<void> call(DueModel due) async {
    await repository.createDue(due);
  }
}
