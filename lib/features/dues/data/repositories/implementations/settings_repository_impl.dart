import 'package:myduesapp/features/dues/data/datasources/settings_datasource.dart';
import 'package:myduesapp/features/dues/data/models/settings_model.dart';
import 'package:myduesapp/features/dues/data/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDatasource datasource;

  SettingsRepositoryImpl({required this.datasource});

  @override
  Future<SettingsModel?> getBillingDates() async {
    return datasource.getSettings('billing_dates');
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
