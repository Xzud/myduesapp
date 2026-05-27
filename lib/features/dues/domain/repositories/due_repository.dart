import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';

abstract class DueRepository {
  Future<List<DueEntity>> getDues();
  Future<void> createDue(DueEntity due);
  Future<void> createDues(List<DueEntity> dues);
  Future<void> setPaid(int id, bool paid);
  Future<void> clearAllData();
}
