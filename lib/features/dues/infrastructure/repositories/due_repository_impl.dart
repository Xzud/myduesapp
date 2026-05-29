import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/infrastructure/datasources/due_datasource.dart';
import 'package:myduesapp/features/dues/infrastructure/models/due_model.dart';

class DueRepositoryImpl implements DueRepository {
  final DueDatasource datasource;

  DueRepositoryImpl({required this.datasource});

  @override
  Future<List<DueEntity>> getDues() async {
    final models = await datasource.getDues();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> createDue(DueEntity due) async {
    await datasource.createDue(DueModel.fromEntity(due));
  }

  @override
  Future<void> createDues(List<DueEntity> dues) async {
    await datasource.createDues(dues.map(DueModel.fromEntity).toList());
  }

  @override
  Future<void> updateDue(DueEntity due) async {
    await datasource.updateDue(DueModel.fromEntity(due));
  }

  @override
  Future<void> deleteDue(int id) async => datasource.deleteDue(id);

  @override
  Future<void> setPaid(int id, bool paid) async => datasource.setPaid(id, paid);

  @override
  Future<void> clearAllData() async => datasource.clearAllData();
}
