abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleDueReminder({
    required int dueId,
    required String title,
    required String body,
    required DateTime scheduledAtLocal,
  });
  Future<void> cancelAllDueReminders();
}
