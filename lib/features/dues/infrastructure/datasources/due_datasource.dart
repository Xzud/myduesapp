import 'package:myduesapp/features/dues/infrastructure/models/due_model.dart'
    show DueModel;
import 'package:myduesapp/features/dues/infrastructure/models/recurring_template_model.dart'
    show RecurringTemplateModel;
import 'package:sqflite/sqflite.dart';

abstract class DueDatasource {
  Future<List<DueModel>> getDues();
  Future<void> createDue(DueModel due);
  Future<void> createDues(List<DueModel> dues);
  Future<void> updateDue(DueModel due);
  Future<void> deleteDue(int id);
  Future<void> deleteDues(List<int> ids);
  Future<void> setPaid(int id, bool paid);
  Future<List<RecurringTemplateModel>> getRecurringTemplates();
  Future<void> createRecurringTemplate(RecurringTemplateModel template);
  Future<void> updateRecurringTemplate(RecurringTemplateModel template);
  Future<void> clearAllData();
}

class DueDatasourceImpl implements DueDatasource {
  Database database;

  DueDatasourceImpl({required this.database});

  @override
  Future<List<DueModel>> getDues() async {
    final result = await database.query(
      'dues',
      orderBy: 'due_date ASC, id ASC',
    );
    return result.map(DueModel.fromMap).toList();
  }

  @override
  Future<void> createDue(DueModel due) async {
    await database.insert('dues', _cleanMap(due.toMap()));
  }

  @override
  Future<void> createDues(List<DueModel> dues) async {
    await database.transaction((txn) async {
      for (final due in dues) {
        await txn.insert('dues', _cleanMap(due.toMap()));
      }
    });
  }

  @override
  Future<void> updateDue(DueModel due) async {
    if (due.id == null) {
      throw ArgumentError('Cannot update a due without an id');
    }

    final values = due.toMap()
      ..remove('id')
      ..['updated_at'] = DateTime.now().toIso8601String();

    await database.update('dues', values, where: 'id = ?', whereArgs: [due.id]);
  }

  @override
  Future<void> deleteDue(int id) async {
    await database.delete('dues', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteDues(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final placeholders = List.filled(ids.length, '?').join(', ');
    await database.delete(
      'dues',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  @override
  Future<void> setPaid(int id, bool paid) async {
    await database.update(
      'dues',
      {'paid': paid ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<RecurringTemplateModel>> getRecurringTemplates() async {
    final result = await database.query(
      'recurring_templates',
      orderBy: 'created_at ASC, id ASC',
    );
    return result.map(RecurringTemplateModel.fromMap).toList();
  }

  @override
  Future<void> createRecurringTemplate(RecurringTemplateModel template) async {
    await database.insert(
      'recurring_templates',
      _cleanMap(template.toMap()),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateRecurringTemplate(RecurringTemplateModel template) async {
    final values = template.toMap()
      ..remove('id')
      ..['updated_at'] = DateTime.now().toIso8601String();

    await database.update(
      'recurring_templates',
      _cleanMap(values),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  @override
  Future<void> clearAllData() async {
    await database.delete('dues');
    await database.delete('recurring_templates');
  }

  Map<String, dynamic> _cleanMap(Map<String, dynamic> values) {
    final out = <String, dynamic>{};
    for (final entry in values.entries) {
      if (entry.value != null) {
        out[entry.key] = entry.value;
      }
    }
    return out;
  }
}
