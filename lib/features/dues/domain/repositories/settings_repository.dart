import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';

abstract class SettingsRepository {
  Future<List<int>> getBillingDates();
  Future<void> setBillingDates(List<int> values);
  Future<BillingPeriodMode> getDefaultBillingPeriodMode();
  Future<void> setDefaultBillingPeriodMode(BillingPeriodMode mode);
  Future<bool> getRemindersEnabled();
  Future<void> setRemindersEnabled(bool enabled);
  Future<int> getReminderOffsetDays();
  Future<void> setReminderOffsetDays(int days);
  Future<DueFilterState> getDueFilterState();
  Future<void> setDueFilterState(DueFilterState state);
  Future<void> clearAllData();
}
