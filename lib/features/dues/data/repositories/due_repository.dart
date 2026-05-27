import 'package:myduesapp/features/dues/data/models/due_model.dart';

abstract class DueRepository {
  Future<List<DueModel>> getDues();
  Future<void> createDue(DueModel due);
  Future<void> createDues(List<DueModel> dues);
  Future<void> setPaid(int id, bool paid);
  Future<void> clearAllData();
}
