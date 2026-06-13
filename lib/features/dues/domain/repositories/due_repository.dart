import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';

abstract class DueRepository {
  Future<List<DueEntity>> getDues();
  Future<void> createDue(DueEntity due);
  Future<void> createDues(List<DueEntity> dues);
  Future<void> updateDue(DueEntity due);
  Future<void> deleteDue(int id);
  Future<void> deleteDues(List<int> ids);
  Future<void> setPaid(int id, bool paid);
  Future<List<RecurringTemplateEntity>> getRecurringTemplates();
  Future<void> createRecurringTemplate(RecurringTemplateEntity template);
  Future<void> updateRecurringTemplate(RecurringTemplateEntity template);
  Future<void> clearAllData();
}
