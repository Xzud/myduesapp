import 'package:myduesapp/features/dues/data/models/settings_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class SettingsDatasource {
  Future<SettingsModel?> getSettings(String key);
  Future<void> setSettings(String key, dynamic value);
}

class SettingsDatasourceImpl implements SettingsDatasource {
  Database database;

  SettingsDatasourceImpl({required this.database});

  @override
  Future<SettingsModel?> getSettings(String key) async {
    List<Map<String, dynamic>> maps = await database.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return SettingsModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> setSettings(String key, dynamic value) async {
    SettingsModel settings = SettingsModel.create(key: key, value: value);

    await database.insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
