import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due, MonthlyDue;
import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';

class FilterDues {
  List<MonthlyDue> call({
    required List<MonthlyDue> months,
    required DueFilterState filterState,
    String searchQuery = '',
    DateTime? referenceDate,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final now = referenceDate ?? DateTime.now();

    return months
        .map((month) {
          final filtered = month.dues.where((due) {
            return _matchesSearch(due, normalizedQuery) &&
                _matchesQuickView(due, filterState.quickView, now) &&
                _matchesStatus(due, filterState.status, now) &&
                _matchesType(due, filterState.type) &&
                _matchesMonth(month.month, filterState.month);
          }).toList();

          if (filtered.isEmpty) {
            return null;
          }

          return MonthlyDue(month: month.month, dues: filtered);
        })
        .whereType<MonthlyDue>()
        .toList();
  }

  bool _matchesSearch(Due due, String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return due.name.toLowerCase().contains(normalizedQuery);
  }

  bool _matchesQuickView(
    Due due,
    DueQuickView quickView,
    DateTime referenceDate,
  ) {
    switch (quickView) {
      case DueQuickView.all:
        return true;
      case DueQuickView.overdue:
        return _isOverdue(due, referenceDate);
      case DueQuickView.dueToday:
        return _isDueToday(due, referenceDate);
      case DueQuickView.upcoming:
        return _isUpcoming(due, referenceDate);
      case DueQuickView.unpaid:
        return !due.paid;
      case DueQuickView.recurring:
        return due.recurring;
    }
  }

  bool _matchesStatus(Due due, DueStatusFilter status, DateTime referenceDate) {
    switch (status) {
      case DueStatusFilter.all:
        return true;
      case DueStatusFilter.paid:
        return due.paid;
      case DueStatusFilter.unpaid:
        return !due.paid;
      case DueStatusFilter.overdue:
        return _isOverdue(due, referenceDate);
      case DueStatusFilter.dueToday:
        return _isDueToday(due, referenceDate);
      case DueStatusFilter.upcoming:
        return _isUpcoming(due, referenceDate);
    }
  }

  bool _matchesType(Due due, DueTypeFilter type) {
    switch (type) {
      case DueTypeFilter.all:
        return true;
      case DueTypeFilter.recurring:
        return due.recurring;
      case DueTypeFilter.installment:
        return !due.recurring &&
            ((due.installmentIndex != null && due.installmentCount != null) ||
                (due.loanId?.isNotEmpty ?? false));
      case DueTypeFilter.single:
        return !due.recurring &&
            due.installmentIndex == null &&
            due.installmentCount == null &&
            !(due.loanId?.isNotEmpty ?? false);
    }
  }

  bool _matchesMonth(String monthLabel, String? selectedMonth) {
    if (selectedMonth == null || selectedMonth.isEmpty) {
      return true;
    }

    return monthLabel == selectedMonth;
  }

  bool _isOverdue(Due due, DateTime referenceDate) {
    if (due.paid) {
      return false;
    }

    final effectiveDate = _effectiveDate(due);
    if (effectiveDate == null) {
      return false;
    }

    final dueDate = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    return dueDate.isBefore(today);
  }

  bool _isDueToday(Due due, DateTime referenceDate) {
    if (due.paid) {
      return false;
    }

    final effectiveDate = _effectiveDate(due);
    if (effectiveDate == null) {
      return false;
    }

    return effectiveDate.year == referenceDate.year &&
        effectiveDate.month == referenceDate.month &&
        effectiveDate.day == referenceDate.day;
  }

  bool _isUpcoming(Due due, DateTime referenceDate) {
    if (due.paid) {
      return false;
    }

    final effectiveDate = _effectiveDate(due);
    if (effectiveDate == null) {
      return false;
    }

    final dueDate = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    return dueDate.isAfter(today);
  }

  DateTime? _effectiveDate(Due due) {
    final dueDate = due.dueDate?.trim();
    if (dueDate != null && dueDate.isNotEmpty) {
      return DateTime.tryParse(dueDate);
    }

    final createdAt = due.createdAt?.trim();
    if (createdAt != null && createdAt.isNotEmpty) {
      return DateTime.tryParse(createdAt);
    }

    return null;
  }
}
