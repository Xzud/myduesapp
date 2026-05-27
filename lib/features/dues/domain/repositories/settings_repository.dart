abstract class SettingsRepository {
  Future<List<int>> getBillingDates();
  Future<void> setBillingDates(List<int> values);
  Future<void> clearAllData();
}
