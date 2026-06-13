import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/get_default_billing_period_mode.dart';
import 'package:myduesapp/features/dues/application/usecases/get_reminder_offset_days.dart';
import 'package:myduesapp/features/dues/application/usecases/get_reminders_enabled.dart';
import 'package:myduesapp/features/dues/application/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/application/usecases/request_reminder_permissions.dart';
import 'package:myduesapp/features/dues/application/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/application/usecases/set_reminder_offset_days.dart';
import 'package:myduesapp/features/dues/application/usecases/set_default_billing_period_mode.dart';
import 'package:myduesapp/features/dues/application/usecases/set_reminders_enabled.dart';
import 'package:myduesapp/features/dues/application/usecases/set_payment_dates.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_due_reminders.dart';
import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/presentation/controllers/settings_controller.dart';

class MockGetPaymentDates extends Mock implements GetPaymentDates {}

class MockSetPaymentDates extends Mock implements SetPaymentDates {}

class MockGetDefaultBillingPeriodMode extends Mock
    implements GetDefaultBillingPeriodMode {}

class MockSetDefaultBillingPeriodMode extends Mock
    implements SetDefaultBillingPeriodMode {}

class MockGetRemindersEnabled extends Mock implements GetRemindersEnabled {}

class MockSetRemindersEnabled extends Mock implements SetRemindersEnabled {}

class MockGetReminderOffsetDays extends Mock implements GetReminderOffsetDays {}

class MockSetReminderOffsetDays extends Mock implements SetReminderOffsetDays {}

class MockRequestReminderPermissions extends Mock
    implements RequestReminderPermissions {}

class MockSyncDueReminders extends Mock implements SyncDueReminders {}

class MockResetAllData extends Mock implements ResetAllData {}

void main() {
  setUpAll(() {
    registerFallbackValue(BillingPeriodMode.single);
  });

  late SettingsController controller;
  late MockGetPaymentDates mockGetPaymentDates;
  late MockSetPaymentDates mockSetPaymentDates;
  late MockGetDefaultBillingPeriodMode mockGetDefaultBillingPeriodMode;
  late MockSetDefaultBillingPeriodMode mockSetDefaultBillingPeriodMode;
  late MockGetRemindersEnabled mockGetRemindersEnabled;
  late MockSetRemindersEnabled mockSetRemindersEnabled;
  late MockGetReminderOffsetDays mockGetReminderOffsetDays;
  late MockSetReminderOffsetDays mockSetReminderOffsetDays;
  late MockRequestReminderPermissions mockRequestReminderPermissions;
  late MockSyncDueReminders mockSyncDueReminders;
  late MockResetAllData mockResetAllData;

  setUp(() {
    mockGetPaymentDates = MockGetPaymentDates();
    mockSetPaymentDates = MockSetPaymentDates();
    mockGetDefaultBillingPeriodMode = MockGetDefaultBillingPeriodMode();
    mockSetDefaultBillingPeriodMode = MockSetDefaultBillingPeriodMode();
    mockGetRemindersEnabled = MockGetRemindersEnabled();
    mockSetRemindersEnabled = MockSetRemindersEnabled();
    mockGetReminderOffsetDays = MockGetReminderOffsetDays();
    mockSetReminderOffsetDays = MockSetReminderOffsetDays();
    mockRequestReminderPermissions = MockRequestReminderPermissions();
    mockSyncDueReminders = MockSyncDueReminders();
    mockResetAllData = MockResetAllData();
    when(() => mockGetRemindersEnabled.call()).thenAnswer((_) async => false);
    when(() => mockGetReminderOffsetDays.call()).thenAnswer((_) async => 1);
    when(
      () => mockRequestReminderPermissions.call(),
    ).thenAnswer((_) async => true);
    when(() => mockSyncDueReminders.call()).thenAnswer((_) async {});
    controller = SettingsController(
      getPaymentDates: mockGetPaymentDates,
      setPaymentDates: mockSetPaymentDates,
      getDefaultBillingPeriodMode: mockGetDefaultBillingPeriodMode,
      setDefaultBillingPeriodMode: mockSetDefaultBillingPeriodMode,
      getRemindersEnabled: mockGetRemindersEnabled,
      setRemindersEnabled: mockSetRemindersEnabled,
      getReminderOffsetDays: mockGetReminderOffsetDays,
      setReminderOffsetDays: mockSetReminderOffsetDays,
      requestReminderPermissions: mockRequestReminderPermissions,
      syncDueReminders: mockSyncDueReminders,
      resetAllData: mockResetAllData,
    );
  });

  test('reset should clear local billing days after success', () async {
    when(() => mockResetAllData.call()).thenAnswer((_) async {});
    when(() => mockGetPaymentDates.call()).thenAnswer((_) async => ['5', '15']);
    when(
      () => mockGetDefaultBillingPeriodMode.call(),
    ).thenAnswer((_) async => BillingPeriodMode.multiple);

    await controller.fetchPaymentDates();
    expect(controller.billingDays, [5, 15]);
    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.multiple);

    await controller.resetData();

    expect(controller.billingDays, isEmpty);
    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.single);
    expect(controller.remindersEnabled, false);
    expect(controller.reminderOffsetDays, 1);
    verify(() => mockResetAllData.call()).called(1);
    verify(() => mockSyncDueReminders.call()).called(1);
  });

  test('should load billing days default mode and reminder settings', () async {
    when(() => mockGetPaymentDates.call()).thenAnswer((_) async => ['15', '5']);
    when(
      () => mockGetDefaultBillingPeriodMode.call(),
    ).thenAnswer((_) async => BillingPeriodMode.single);
    when(() => mockGetRemindersEnabled.call()).thenAnswer((_) async => true);
    when(() => mockGetReminderOffsetDays.call()).thenAnswer((_) async => 3);

    await controller.fetchPaymentDates();

    expect(controller.billingDays, [5, 15]);
    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.single);
    expect(controller.remindersEnabled, true);
    expect(controller.reminderOffsetDays, 3);
    verify(() => mockGetPaymentDates.call()).called(1);
    verify(() => mockGetDefaultBillingPeriodMode.call()).called(1);
    verify(() => mockGetRemindersEnabled.call()).called(1);
    verify(() => mockGetReminderOffsetDays.call()).called(1);
  });

  test('should persist default billing period mode', () async {
    when(
      () => mockSetDefaultBillingPeriodMode.call(BillingPeriodMode.multiple),
    ).thenAnswer((_) async {});

    await controller.updateDefaultBillingPeriodMode(BillingPeriodMode.multiple);

    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.multiple);
    expect(controller.errorMessage, isNull);
    verify(
      () => mockSetDefaultBillingPeriodMode.call(BillingPeriodMode.multiple),
    ).called(1);
  });

  test('should enable reminders after permission is granted', () async {
    when(() => mockSetRemindersEnabled.call(true)).thenAnswer((_) async {});

    await controller.updateRemindersEnabled(true);

    expect(controller.remindersEnabled, true);
    expect(controller.errorMessage, isNull);
    verify(() => mockRequestReminderPermissions.call()).called(1);
    verify(() => mockSetRemindersEnabled.call(true)).called(1);
    verify(() => mockSyncDueReminders.call()).called(1);
  });

  test('should not enable reminders when permission is denied', () async {
    when(
      () => mockRequestReminderPermissions.call(),
    ).thenAnswer((_) async => false);

    await controller.updateRemindersEnabled(true);

    expect(controller.remindersEnabled, false);
    expect(controller.errorMessage, 'Notification permission was not granted');
    verifyNever(() => mockSetRemindersEnabled.call(any()));
    verifyNever(() => mockSyncDueReminders.call());
  });

  test('should persist reminder offset days and resync reminders', () async {
    when(() => mockSetReminderOffsetDays.call(7)).thenAnswer((_) async {});

    await controller.updateReminderOffsetDays(7);

    expect(controller.reminderOffsetDays, 7);
    expect(controller.errorMessage, isNull);
    verify(() => mockSetReminderOffsetDays.call(7)).called(1);
    verify(() => mockSyncDueReminders.call()).called(1);
  });
}
