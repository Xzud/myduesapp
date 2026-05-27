import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';
import 'package:myduesapp/features/dues/infrastructure/datasources/settings_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDatasource datasource;

  SettingsRepositoryImpl({required this.datasource});

  @override
  Future<List<int>> getBillingDates() async {
    final settings = await datasource.getSettings('billing_dates');
    final decoded = settings?.getDecodedValue();
    if (decoded is! List) {
      return [];
    }

    final values = <int>[];
    for (final item in decoded) {
      final value = item is int ? item : int.tryParse(item.toString());
      if (value != null && value >= 1 && value <= 31) {
        values.add(value);
      }
    }

    return values.toSet().toList()..sort();
  }

  @override
  Future<void> setBillingDates(List<int> values) async {
    await datasource.setSettings('billing_dates', values);
  }

  @override
  Future<void> clearAllData() async {
    await datasource.clearAllData();
  }
}
