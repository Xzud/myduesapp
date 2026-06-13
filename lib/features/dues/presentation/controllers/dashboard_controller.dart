import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/application/usecases/get_dashboard_summary.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_due_reminders.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_recurring_templates.dart';
import 'package:myduesapp/features/dues/domain/entities/dashboard_summary_entity.dart';

class DashboardController extends ChangeNotifier {
  final GetDashboardSummary getDashboardSummary;
  final SyncRecurringTemplates syncRecurringTemplates;
  final SyncDueReminders syncDueReminders;

  DashboardController({
    required this.getDashboardSummary,
    required this.syncRecurringTemplates,
    required this.syncDueReminders,
  });

  DashboardSummary _summary = const DashboardSummary.empty();
  DashboardSummary get summary => _summary;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadSummary({DateTime? referenceDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final changed = await syncRecurringTemplates.call();
      if (changed) {
        await syncDueReminders.call();
      }
      _summary = await getDashboardSummary.call(referenceDate: referenceDate);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Dashboard summary load failed: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
