import 'package:myduesapp/features/dues/infrastructure/models/due_model.dart'
    show DueModel;
import 'package:sqflite/sqflite.dart';

abstract class DueDatasource {
  Future<List<DueModel>> getDues();
  Future<void> createDue(DueModel due);
  Future<void> createDues(List<DueModel> dues);
  Future<void> updateDue(DueModel due);
  Future<void> deleteDue(int id);
  Future<void> setPaid(int id, bool paid);
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
    await database.insert('dues', due.toMap());
  }

  @override
  Future<void> createDues(List<DueModel> dues) async {
    await database.transaction((txn) async {
      for (final due in dues) {
        await txn.insert('dues', due.toMap());
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
  Future<void> setPaid(int id, bool paid) async {
    await database.update(
      'dues',
      {'paid': paid ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAllData() async {
    await database.delete('dues');
  }
}
