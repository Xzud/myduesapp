import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
    final path = join(await getDatabasesPath(), 'mydues.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dues(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        amount REAL,
        recurring INTEGER DEFAULT 0,
        recurring_interval INTEGER DEFAULT 1,
        recurring_template_id TEXT,
        generated_from_template INTEGER DEFAULT 0,
        day_of_month INTEGER,
        loan_id TEXT,
        installment_index INTEGER,
        installment_count INTEGER,
        due_date TEXT,
        paid INTEGER DEFAULT 0,
        complete INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE recurring_templates(
        id TEXT PRIMARY KEY,
        name TEXT,
        amount REAL,
        billing_day INTEGER,
        interval_months INTEGER,
        start_date TEXT,
        active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_dues_recurring_template_date
      ON dues(recurring_template_id, due_date)
      WHERE recurring_template_id IS NOT NULL;
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE dues ADD COLUMN loan_id TEXT');
      await db.execute('ALTER TABLE dues ADD COLUMN installment_index INTEGER');
      await db.execute('ALTER TABLE dues ADD COLUMN installment_count INTEGER');
      await db.execute('ALTER TABLE dues ADD COLUMN due_date TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings(
          key TEXT PRIMARY KEY,
          value TEXT
        );
      ''');
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE dues ADD COLUMN recurring_template_id TEXT',
      );
      await db.execute(
        'ALTER TABLE dues ADD COLUMN generated_from_template INTEGER DEFAULT 0',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recurring_templates(
          id TEXT PRIMARY KEY,
          name TEXT,
          amount REAL,
          billing_day INTEGER,
          interval_months INTEGER,
          start_date TEXT,
          active INTEGER DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
      ''');
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_dues_recurring_template_date
        ON dues(recurring_template_id, due_date)
        WHERE recurring_template_id IS NOT NULL;
      ''');
    }
  }
}
