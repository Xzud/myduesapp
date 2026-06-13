import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/domain/entities/reminder_settings.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';
import 'package:myduesapp/features/dues/infrastructure/datasources/settings_datasource.dart';

const _billingDatesKey = 'billing_dates';
const _defaultBillingPeriodModeKey = 'default_billing_period_mode';
const _remindersEnabledKey = 'reminders_enabled';
const _reminderOffsetDaysKey = 'reminder_offset_days';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDatasource datasource;

  SettingsRepositoryImpl({required this.datasource});

  @override
  Future<List<int>> getBillingDates() async {
    final settings = await datasource.getSettings(_billingDatesKey);
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
    await datasource.setSettings(_billingDatesKey, values);
  }

  @override
  Future<BillingPeriodMode> getDefaultBillingPeriodMode() async {
    final settings = await datasource.getSettings(_defaultBillingPeriodModeKey);
    return billingPeriodModeFromValue(settings?.getDecodedValue());
  }

  @override
  Future<void> setDefaultBillingPeriodMode(BillingPeriodMode mode) async {
    await datasource.setSettings(_defaultBillingPeriodModeKey, mode.name);
  }

  @override
  Future<bool> getRemindersEnabled() async {
    final settings = await datasource.getSettings(_remindersEnabledKey);
    final decoded = settings?.getDecodedValue();
    if (decoded is bool) {
      return decoded;
    }
    if (decoded is String) {
      return decoded.toLowerCase() == 'true';
    }
    return defaultRemindersEnabled;
  }

  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    await datasource.setSettings(_remindersEnabledKey, enabled);
  }

  @override
  Future<int> getReminderOffsetDays() async {
    final settings = await datasource.getSettings(_reminderOffsetDaysKey);
    final decoded = settings?.getDecodedValue();
    final value = decoded is int ? decoded : int.tryParse(decoded.toString());
    if (value == null || !isValidReminderOffsetDays(value)) {
      return defaultReminderOffsetDays;
    }
    return value;
  }

  @override
  Future<void> setReminderOffsetDays(int days) async {
    if (!isValidReminderOffsetDays(days)) {
      throw ArgumentError('Unsupported reminder offset: $days');
    }
    await datasource.setSettings(_reminderOffsetDaysKey, days);
  }

  @override
  Future<void> clearAllData() async {
    await datasource.clearAllData();
  }
}
