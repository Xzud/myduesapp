import 'package:myduesapp/features/dues/data/%20models/settings_model.dart';

abstract class SettingsRepository {
  Future<SettingsModel?> getBillingDates();
  Future<void> setBillingDates(List<int> values);
}
