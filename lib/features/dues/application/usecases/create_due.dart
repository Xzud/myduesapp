import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class CreateDue {
  final DueRepository repository;

  CreateDue({required this.repository});

  Future<void> call(DueEntity due) async {
    await repository.createDue(due);
  }
}
