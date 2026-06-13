import 'package:flutter/foundation.dart';
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
import 'package:myduesapp/features/dues/domain/entities/reminder_settings.dart';

class SettingsController extends ChangeNotifier {
  final GetPaymentDates getPaymentDates;
  final SetPaymentDates setPaymentDates;
  final GetDefaultBillingPeriodMode getDefaultBillingPeriodMode;
  final SetDefaultBillingPeriodMode setDefaultBillingPeriodMode;
  final GetRemindersEnabled getRemindersEnabled;
  final SetRemindersEnabled setRemindersEnabled;
  final GetReminderOffsetDays getReminderOffsetDays;
  final SetReminderOffsetDays setReminderOffsetDays;
  final RequestReminderPermissions requestReminderPermissions;
  final SyncDueReminders syncDueReminders;
  final ResetAllData resetAllData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SettingsController({
    required this.getPaymentDates,
    required this.setPaymentDates,
    required this.getDefaultBillingPeriodMode,
    required this.setDefaultBillingPeriodMode,
    required this.getRemindersEnabled,
    required this.setRemindersEnabled,
    required this.getReminderOffsetDays,
    required this.setReminderOffsetDays,
    required this.requestReminderPermissions,
    required this.syncDueReminders,
    required this.resetAllData,
  });

  List<int> _billingDays = [];
  List<int> get billingDays => List.unmodifiable(_billingDays);

  BillingPeriodMode _defaultBillingPeriodMode = BillingPeriodMode.single;
  BillingPeriodMode get defaultBillingPeriodMode => _defaultBillingPeriodMode;

  bool _remindersEnabled = defaultRemindersEnabled;
  bool get remindersEnabled => _remindersEnabled;

  int _reminderOffsetDays = defaultReminderOffsetDays;
  int get reminderOffsetDays => _reminderOffsetDays;

  Future<void> fetchPaymentDates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await getPaymentDates.call();
      final defaultMode = await getDefaultBillingPeriodMode.call();
      final remindersEnabled = await getRemindersEnabled.call();
      final reminderOffsetDays = await getReminderOffsetDays.call();
      final days = <int>[];
      for (final v in raw) {
        final d = int.tryParse(v);
        if (d != null) days.add(d);
      }
      days.sort();
      _billingDays = days.toSet().toList()..sort();
      _defaultBillingPeriodMode = defaultMode;
      _remindersEnabled = remindersEnabled;
      _reminderOffsetDays = reminderOffsetDays;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBillingDay(int day) async {
    if (day < 1 || day > 31) {
      _errorMessage = 'Billing day must be between 1 and 31';
      notifyListeners();
      return;
    }

    final next = {..._billingDays, day}.toList()..sort();
    await _persist(next);
  }

  Future<void> removeBillingDay(int day) async {
    final next = _billingDays.where((d) => d != day).toList()..sort();
    await _persist(next);
  }

  Future<void> updateDefaultBillingPeriodMode(BillingPeriodMode mode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await setDefaultBillingPeriodMode.call(mode);
      _defaultBillingPeriodMode = mode;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRemindersEnabled(bool enabled) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (enabled) {
        final granted = await requestReminderPermissions.call();
        if (!granted) {
          _errorMessage = 'Notification permission was not granted';
          return;
        }
      }

      await setRemindersEnabled.call(enabled);
      _remindersEnabled = enabled;
      await syncDueReminders.call();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReminderOffsetDays(int days) async {
    if (!isValidReminderOffsetDays(days)) {
      _errorMessage = 'Unsupported reminder lead time';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await setReminderOffsetDays.call(days);
      _reminderOffsetDays = days;
      await syncDueReminders.call();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await resetAllData.call();
      _billingDays = [];
      _defaultBillingPeriodMode = BillingPeriodMode.single;
      _remindersEnabled = defaultRemindersEnabled;
      _reminderOffsetDays = defaultReminderOffsetDays;
      await syncDueReminders.call();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist(List<int> next) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await setPaymentDates.call(next);
      _billingDays = next;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
