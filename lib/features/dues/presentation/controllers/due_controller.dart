import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/application/usecases/delete_due.dart';
import 'package:myduesapp/features/dues/application/usecases/end_recurring_series.dart';
import 'package:myduesapp/features/dues/application/usecases/filter_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/get_due_filter_state.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_paid.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_filter_state.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_due_reminders.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_recurring_templates.dart';
import 'package:myduesapp/features/dues/application/usecases/update_due.dart';
import 'package:myduesapp/features/dues/application/usecases/update_recurring_series.dart';
import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';

class DueController extends ChangeNotifier {
  final GetAllDues getAllDues;
  final GetDueFilterState getDueFilterState;
  final SetDueFilterState setDueFilterState;
  final FilterDues filterDues;
  final SetDuePaid setDuePaid;
  final UpdateDue updateDue;
  final DeleteDue deleteDue;
  final UpdateRecurringSeries updateRecurringSeries;
  final EndRecurringSeries endRecurringSeries;
  final SyncRecurringTemplates syncRecurringTemplates;
  final SyncDueReminders syncDueReminders;

  DueController({
    required this.getAllDues,
    required this.getDueFilterState,
    required this.setDueFilterState,
    required this.filterDues,
    required this.setDuePaid,
    required this.updateDue,
    required this.deleteDue,
    required this.updateRecurringSeries,
    required this.endRecurringSeries,
    required this.syncRecurringTemplates,
    required this.syncDueReminders,
  });

  List<MonthlyDue> _dues = [];
  List<MonthlyDue> get dues => _dues;
  List<MonthlyDue> get filteredDues => filterDues.call(
    months: _dues,
    filterState: _filterState,
    searchQuery: _searchQuery,
  );

  DueFilterState _filterState = const DueFilterState();
  DueFilterState get filterState => _filterState;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _loadedSavedFilterState = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<String> get availableMonths =>
      _dues.map((month) => month.month).toSet().toList();

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty || !_filterState.isDefault;

  Future<void> fetchDues() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final changed = await syncRecurringTemplates.call();
      if (changed) {
        await syncDueReminders.call();
      }
      _dues = await getAllDues.call();
      if (!_loadedSavedFilterState) {
        _filterState = await getDueFilterState.call();
        _loadedSavedFilterState = true;
      }
      await _syncNormalizedFilterState();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> updateQuickView(DueQuickView value) async {
    await _persistFilterState(_filterState.copyWith(quickView: value));
  }

  Future<void> updateStatusFilter(DueStatusFilter value) async {
    await _persistFilterState(_filterState.copyWith(status: value));
  }

  Future<void> updateTypeFilter(DueTypeFilter value) async {
    await _persistFilterState(_filterState.copyWith(type: value));
  }

  Future<void> updateMonthFilter(String? value) async {
    await _persistFilterState(_filterState.copyWith(month: value));
  }

  Future<void> clearFilters() async {
    _searchQuery = '';
    await _persistFilterState(const DueFilterState());
  }

  Future<void> togglePaid({required int dueId, required bool paid}) async {
    await _runMutation(() async {
      await setDuePaid.call(dueId, paid);
    });
  }

  Future<void> setDueItemsPaid(List<int> dueIds, bool paid) async {
    final ids = dueIds.where((id) => id > 0).toSet().toList()..sort();
    if (ids.isEmpty) {
      return;
    }

    await _runMutation(() async {
      for (final id in ids) {
        await setDuePaid.call(id, paid);
      }
    });
  }

  Future<void> updateDueItem(DueEntity due) async {
    await _runMutation(() async {
      await updateDue.call(due);
    });
  }

  Future<void> deleteDueItem(int dueId) async {
    await _runMutation(() async {
      await deleteDue.call(dueId);
    });
  }

  Future<void> deleteDueItems(List<int> dueIds) async {
    final ids = dueIds.where((id) => id > 0).toSet().toList()..sort();
    if (ids.isEmpty) {
      return;
    }

    await _runMutation(() async {
      for (final id in ids) {
        await deleteDue.call(id);
      }
    });
  }

  Future<void> updateRecurringSeriesItem({
    required String templateId,
    required String name,
    required double amount,
    required int billingDay,
    required int intervalMonths,
  }) async {
    await _runMutation(() async {
      await updateRecurringSeries.call(
        templateId: templateId,
        name: name,
        amount: amount,
        billingDay: billingDay,
        intervalMonths: intervalMonths,
      );
    });
  }

  Future<void> endRecurringSeriesItem(String templateId) async {
    await _runMutation(() async {
      await endRecurringSeries.call(templateId);
    });
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      await syncRecurringTemplates.call();
      _dues = await getAllDues.call();
      await syncDueReminders.call();
      await _syncNormalizedFilterState();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Due mutation failed: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistFilterState(DueFilterState next) async {
    _errorMessage = null;
    _filterState = _normalizeFilterState(next);
    notifyListeners();

    try {
      await setDueFilterState.call(_filterState);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> _syncNormalizedFilterState() async {
    final normalized = _normalizeFilterState(_filterState);
    if (normalized == _filterState) {
      return;
    }

    _filterState = normalized;
    await setDueFilterState.call(_filterState);
  }

  DueFilterState _normalizeFilterState(DueFilterState state) {
    final available = availableMonths.toSet();
    final month = state.month;
    if (month == null || month.isEmpty || available.contains(month)) {
      return state;
    }

    return state.copyWith(month: null);
  }
}
