import 'package:myduesapp/core/notifications/notification_service.dart';

class RequestReminderPermissions {
  final NotificationService notificationService;

  RequestReminderPermissions({required this.notificationService});

  Future<bool> call() async {
    return await notificationService.requestPermissions();
  }
}
