import 'package:myduesapp/features/dues/infrastructure/models/due_model.dart'
    show DueModel;
import 'package:sqflite/sqflite.dart';

abstract class DueDatasource {
  Future<List<DueModel>> getDues();
  Future<void> createDue(DueModel due);
  Future<void> createDues(List<DueModel> dues);
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
