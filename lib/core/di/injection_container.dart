import 'package:get_it/get_it.dart' show GetIt;
import 'package:myduesapp/core/database/database_helper.dart'
    show DatabaseHelper;
import 'package:myduesapp/core/notifications/flutter_local_notification_service.dart';
import 'package:myduesapp/core/notifications/notification_service.dart';
import 'package:myduesapp/features/dues/infrastructure/datasources/due_datasource.dart';
import 'package:myduesapp/features/dues/infrastructure/datasources/settings_datasource.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/infrastructure/repositories/due_repository_impl.dart';
import 'package:myduesapp/features/dues/infrastructure/repositories/settings_repository_impl.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';
import 'package:myduesapp/features/dues/application/usecases/create_recurring_due.dart';
import 'package:myduesapp/features/dues/application/usecases/create_split_due.dart';
import 'package:myduesapp/features/dues/application/usecases/get_default_billing_period_mode.dart';
import 'package:myduesapp/features/dues/application/usecases/get_dashboard_summary.dart';
import 'package:myduesapp/features/dues/application/usecases/delete_due.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/get_reminder_offset_days.dart';
import 'package:myduesapp/features/dues/application/usecases/get_reminders_enabled.dart';
import 'package:myduesapp/features/dues/application/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/application/usecases/request_reminder_permissions.dart';
import 'package:myduesapp/features/dues/application/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/application/usecases/set_reminder_offset_days.dart';
import 'package:myduesapp/features/dues/application/usecases/set_default_billing_period_mode.dart';
import 'package:myduesapp/features/dues/application/usecases/set_reminders_enabled.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_paid.dart';
import 'package:myduesapp/features/dues/application/usecases/set_payment_dates.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_due_reminders.dart';
import 'package:myduesapp/features/dues/application/usecases/update_due.dart';
import 'package:myduesapp/features/dues/presentation/controllers/dashboard_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/settings_controller.dart';
import 'package:sqflite/sqflite.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final db = await DatabaseHelper.instance.database;
  sl.registerLazySingleton<Database>(() => db);

  sl.registerLazySingleton<DueDatasource>(
    () => DueDatasourceImpl(database: sl()),
  );
  sl.registerLazySingleton<SettingsDatasource>(
    () => SettingsDatasourceImpl(database: sl()),
  );

  sl.registerLazySingleton<DueRepository>(
    () => DueRepositoryImpl(datasource: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(datasource: sl()),
  );
  sl.registerLazySingleton<NotificationService>(
    () => FlutterLocalNotificationService(),
  );

  sl.registerLazySingleton<GetAllDues>(() => GetAllDues(repository: sl()));
  sl.registerLazySingleton<GetPaymentDates>(
    () => GetPaymentDates(repository: sl()),
  );
  sl.registerLazySingleton<SetPaymentDates>(
    () => SetPaymentDates(repository: sl()),
  );
  sl.registerLazySingleton<GetDefaultBillingPeriodMode>(
    () => GetDefaultBillingPeriodMode(repository: sl()),
  );
  sl.registerLazySingleton<SetDefaultBillingPeriodMode>(
    () => SetDefaultBillingPeriodMode(repository: sl()),
  );
  sl.registerLazySingleton<GetRemindersEnabled>(
    () => GetRemindersEnabled(repository: sl()),
  );
  sl.registerLazySingleton<SetRemindersEnabled>(
    () => SetRemindersEnabled(repository: sl()),
  );
  sl.registerLazySingleton<GetReminderOffsetDays>(
    () => GetReminderOffsetDays(repository: sl()),
  );
  sl.registerLazySingleton<SetReminderOffsetDays>(
    () => SetReminderOffsetDays(repository: sl()),
  );
  sl.registerLazySingleton<RequestReminderPermissions>(
    () => RequestReminderPermissions(notificationService: sl()),
  );
  sl.registerLazySingleton<CreateSplitDue>(
    () => CreateSplitDue(repository: sl()),
  );
  sl.registerLazySingleton<CreateRecurringDue>(
    () => CreateRecurringDue(repository: sl()),
  );
  sl.registerLazySingleton<GetDashboardSummary>(
    () => GetDashboardSummary(repository: sl()),
  );
  sl.registerLazySingleton<SetDuePaid>(() => SetDuePaid(repository: sl()));
  sl.registerLazySingleton<UpdateDue>(() => UpdateDue(repository: sl()));
  sl.registerLazySingleton<DeleteDue>(() => DeleteDue(repository: sl()));
  sl.registerLazySingleton<SyncDueReminders>(
    () => SyncDueReminders(
      dueRepository: sl(),
      settingsRepository: sl(),
      notificationService: sl(),
    ),
  );
  sl.registerLazySingleton<ResetAllData>(
    () => ResetAllData(dueRepository: sl(), settingsRepository: sl()),
  );

  sl.registerFactory(() => DashboardController(getDashboardSummary: sl()));
  sl.registerFactory(
    () => DueController(
      getAllDues: sl(),
      setDuePaid: sl(),
      updateDue: sl(),
      deleteDue: sl(),
      syncDueReminders: sl(),
    ),
  );
  sl.registerFactory(
    () => DueFormController(
      getPaymentDates: sl(),
      createSplitDue: sl(),
      createRecurringDue: sl(),
      syncDueReminders: sl(),
      getDefaultBillingPeriodMode: sl(),
    ),
  );
  sl.registerFactory(
    () => SettingsController(
      getPaymentDates: sl(),
      setPaymentDates: sl(),
      getDefaultBillingPeriodMode: sl(),
      setDefaultBillingPeriodMode: sl(),
      getRemindersEnabled: sl(),
      setRemindersEnabled: sl(),
      getReminderOffsetDays: sl(),
      setReminderOffsetDays: sl(),
      requestReminderPermissions: sl(),
      syncDueReminders: sl(),
      resetAllData: sl(),
    ),
  );
}
