import 'package:myduesapp/features/dues/data/models/due_model.dart';
import 'package:myduesapp/features/dues/data/datasources/due_datasource.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';

class DueRepositoryImpl implements DueRepository {
  final DueDatasource datasource;

  DueRepositoryImpl({required this.datasource});

  @override
  Future<List<DueModel>> getDues() async {
    return await datasource.getDues();
  }
}
