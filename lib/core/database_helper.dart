import 'package:myduesapp/%20models/due_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mydues.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dues(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        amount REAL,
        recurring INTEGER DEFAULT 0,
        recurring_interval INTEGER DEFAULT 1,
        day_of_month INTEGER,
        paid INTEGER DEFAULT 0,
        complete INTEGER DEFAULT 0,
        CREATED_AT TEXT DEFAULT CURRENT_TIMESTAMP,
        UPDATED_AT TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getDues() async {
    final db = await database;

    var result = await db.query('dues');

    List<Map<String, dynamic>> dues = [];

    if (result.isEmpty) {
      print('No dues found');
      return [];
    }

    for (var item in result) {
      DueModel currentDue = DueModel.fromMap(item);

      if (dues.isEmpty) {
        dues.add({
          'month': currentDue.getMonthYear(),
          'dues': [
            {
              'name': currentDue.name,
              'price': currentDue.amount,
              'paid': currentDue.paid,
            },
          ],
        });
        continue;
      } else {
        for (var due in dues) {
          if (due['month'] == currentDue.getMonthYear()) {
            due['dues'].add({
              'name': currentDue.name,
              'price': currentDue.amount,
              'paid': currentDue.paid,
            });
            break;
          } else {
            dues.add({
              'month': currentDue.getMonthYear(),
              'dues': [
                {
                  'name': currentDue.name,
                  'price': currentDue.amount,
                  'paid': currentDue.paid,
                },
              ],
            });
            break;
          }
        }
      }
    }

    print(result);
    return dues;
  }
}
