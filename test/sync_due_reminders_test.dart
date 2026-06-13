import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/core/notifications/notification_service.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_due_reminders.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class FakeNotificationService implements NotificationService {
  int cancelAllCalls = 0;
  final scheduled = <({int dueId, String title, String body, DateTime at})>[];

  @override
  Future<void> cancelAllDueReminders() async {
    cancelAllCalls += 1;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleDueReminder({
    required int dueId,
    required String title,
    required String body,
    required DateTime scheduledAtLocal,
  }) async {
    scheduled.add((
      dueId: dueId,
      title: title,
      body: body,
      at: scheduledAtLocal,
    ));
  }
}

void main() {
  late MockDueRepository dueRepository;
  late MockSettingsRepository settingsRepository;
  late FakeNotificationService notificationService;

  setUp(() {
    dueRepository = MockDueRepository();
    settingsRepository = MockSettingsRepository();
    notificationService = FakeNotificationService();
  });

  test('should cancel all reminders when reminders are disabled', () async {
    when(
      () => settingsRepository.getRemindersEnabled(),
    ).thenAnswer((_) async => false);

    final usecase = SyncDueReminders(
      dueRepository: dueRepository,
      settingsRepository: settingsRepository,
      notificationService: notificationService,
      now: () => DateTime(2026, 6, 13, 8),
    );

    await usecase.call();

    expect(notificationService.cancelAllCalls, 1);
    expect(notificationService.scheduled, isEmpty);
    verify(() => settingsRepository.getRemindersEnabled()).called(1);
    verifyNever(() => settingsRepository.getReminderOffsetDays());
    verifyNever(() => dueRepository.getDues());
  });

  test('should schedule reminders only for future unpaid dues', () async {
    when(
      () => settingsRepository.getRemindersEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => settingsRepository.getReminderOffsetDays(),
    ).thenAnswer((_) async => 1);
    when(() => dueRepository.getDues()).thenAnswer(
      (_) async => [
        DueEntity(
          id: 1,
          name: 'Internet',
          amount: 1800,
          dayOfMonth: 15,
          dueDate: DateTime(2026, 6, 15).toIso8601String(),
        ),
        DueEntity(
          id: 2,
          name: 'Paid',
          amount: 500,
          dayOfMonth: 15,
          dueDate: DateTime(2026, 6, 15).toIso8601String(),
          paid: true,
        ),
        DueEntity(
          id: 3,
          name: 'Past',
          amount: 500,
          dayOfMonth: 13,
          dueDate: DateTime(2026, 6, 13).toIso8601String(),
        ),
        const DueEntity(
          id: 4,
          name: 'Missing date',
          amount: 500,
          dayOfMonth: 20,
        ),
      ],
    );

    final usecase = SyncDueReminders(
      dueRepository: dueRepository,
      settingsRepository: settingsRepository,
      notificationService: notificationService,
      now: () => DateTime(2026, 6, 13, 10),
    );

    await usecase.call();

    expect(notificationService.cancelAllCalls, 1);
    expect(notificationService.scheduled, hasLength(1));
    expect(notificationService.scheduled.single.dueId, 1);
    expect(notificationService.scheduled.single.at, DateTime(2026, 6, 14, 9));
  });
}
