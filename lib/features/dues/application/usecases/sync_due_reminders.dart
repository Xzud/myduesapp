import 'package:myduesapp/core/notifications/notification_service.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class SyncDueReminders {
  final DueRepository dueRepository;
  final SettingsRepository settingsRepository;
  final NotificationService notificationService;
  final DateTime Function() now;

  SyncDueReminders({
    required this.dueRepository,
    required this.settingsRepository,
    required this.notificationService,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<void> call() async {
    await notificationService.cancelAllDueReminders();

    final remindersEnabled = await settingsRepository.getRemindersEnabled();
    if (!remindersEnabled) {
      return;
    }

    final offsetDays = await settingsRepository.getReminderOffsetDays();
    final currentTime = now();
    final dues = await dueRepository.getDues();

    for (final due in dues) {
      final reminderTime = _buildReminderTime(due: due, offsetDays: offsetDays);
      if (due.id == null ||
          due.paid ||
          reminderTime == null ||
          !reminderTime.isAfter(currentTime)) {
        continue;
      }

      await notificationService.scheduleDueReminder(
        dueId: due.id!,
        title: due.name,
        body: _buildReminderBody(due, offsetDays),
        scheduledAtLocal: reminderTime,
      );
    }
  }

  DateTime? _buildReminderTime({
    required DueEntity due,
    required int offsetDays,
  }) {
    final dueDateValue = due.dueDate;
    if (dueDateValue == null || dueDateValue.isEmpty) {
      return null;
    }

    final dueDate = DateTime.tryParse(dueDateValue);
    if (dueDate == null) {
      return null;
    }

    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    ).subtract(Duration(days: offsetDays));
  }

  String _buildReminderBody(DueEntity due, int offsetDays) {
    final dueDate = DateTime.tryParse(due.dueDate ?? '');
    final dueDateLabel = dueDate == null
        ? 'soon'
        : '${_monthName(dueDate.month)} ${dueDate.day}, ${dueDate.year}';
    final amountLabel = due.amount.toStringAsFixed(2);
    if (offsetDays == 0) {
      return 'Due today: $amountLabel on $dueDateLabel.';
    }
    if (offsetDays == 1) {
      return 'Due tomorrow: $amountLabel on $dueDateLabel.';
    }
    return 'Due in $offsetDays days: $amountLabel on $dueDateLabel.';
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}
