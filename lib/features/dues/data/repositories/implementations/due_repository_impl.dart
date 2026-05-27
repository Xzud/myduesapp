import 'package:myduesapp/features/dues/data/datasources/due_datasource.dart';
import 'package:myduesapp/features/dues/data/models/due_model.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';

class DueRepositoryImpl implements DueRepository {
  final DueDatasource datasource;

  DueRepositoryImpl({required this.datasource});

  @override
  Future<List<DueModel>> getDues() async => datasource.getDues();

  @override
  Future<void> createDue(DueModel due) async => datasource.createDue(due);

  @override
  Future<void> createDues(List<DueModel> dues) async =>
      datasource.createDues(dues);

  @override
  Future<void> setPaid(int id, bool paid) async => datasource.setPaid(id, paid);

  @override
  Future<void> clearAllData() async => datasource.clearAllData();
}
