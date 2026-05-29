import 'package:myduesapp/features/dues/domain/entities/dashboard_summary_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class GetDashboardSummary {
  final DueRepository repository;

  GetDashboardSummary({required this.repository});

  Future<DashboardSummary> call({DateTime? referenceDate}) async {
    final dues = await repository.getDues();
    if (dues.isEmpty) {
      return const DashboardSummary.empty();
    }

    final anchor = referenceDate ?? DateTime.now();
    final today = DateTime(anchor.year, anchor.month, anchor.day);
    final monthlyMap = <String, _MonthlyAccumulator>{};

    var totalCount = 0;
    var paidCount = 0;
    var unpaidCount = 0;
    var overdueCount = 0;
    var dueTodayCount = 0;
    var upcomingCount = 0;
    var recurringCount = 0;
    var oneTimeCount = 0;
    var completeCount = 0;
    var totalAmount = 0.0;
    var paidAmount = 0.0;
    var unpaidAmount = 0.0;
    var overdueAmount = 0.0;

    for (final due in dues) {
      totalCount += 1;
      totalAmount += due.amount;

      final isPaid = due.paid;
      final isComplete = due.complete;
      final isSettled = isPaid || isComplete;
      final effectiveDate = _effectiveDate(due, anchor);
      final dueDate = _parseDate(due.dueDate);
      final monthKey = _monthYear(effectiveDate);

      monthlyMap.putIfAbsent(
        monthKey,
        () => _MonthlyAccumulator(
          month: monthKey,
          sortKey: DateTime(effectiveDate.year, effectiveDate.month),
        ),
      );
      monthlyMap[monthKey]!.add(
        due,
        dueDate: dueDate,
        today: today,
        isSettled: isSettled,
      );

      if (isPaid) {
        paidCount += 1;
        paidAmount += due.amount;
      }

      if (!isSettled) {
        unpaidCount += 1;
        unpaidAmount += due.amount;
      }

      if (isComplete) {
        completeCount += 1;
      }

      if (due.recurring) {
        recurringCount += 1;
      } else {
        oneTimeCount += 1;
      }

      if (dueDate != null) {
        final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        if (dueDay.isBefore(today) && !isSettled) {
          overdueCount += 1;
          overdueAmount += due.amount;
        } else if (_isSameDay(dueDay, today) && !isSettled) {
          dueTodayCount += 1;
        } else if (dueDay.isAfter(today) && !isSettled) {
          upcomingCount += 1;
        }
      }
    }

    final monthlySummaries = monthlyMap.values.toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    return DashboardSummary(
      totalCount: totalCount,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
      overdueCount: overdueCount,
      dueTodayCount: dueTodayCount,
      upcomingCount: upcomingCount,
      recurringCount: recurringCount,
      oneTimeCount: oneTimeCount,
      completeCount: completeCount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      unpaidAmount: unpaidAmount,
      overdueAmount: overdueAmount,
      monthlySummaries: monthlySummaries
          .map(
            (summary) => DashboardMonthlySummary(
              month: summary.month,
              totalCount: summary.totalCount,
              paidCount: summary.paidCount,
              unpaidCount: summary.unpaidCount,
              overdueCount: summary.overdueCount,
              totalAmount: summary.totalAmount,
              paidAmount: summary.paidAmount,
              unpaidAmount: summary.unpaidAmount,
            ),
          )
          .toList(),
    );
  }

  DateTime _effectiveDate(DueEntity due, DateTime fallback) {
    return _parseDate(due.dueDate) ??
        _parseDate(due.createdAt) ??
        DateTime(fallback.year, fallback.month, fallback.day);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _monthYear(DateTime date) {
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
    return '${months[date.month]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MonthlyAccumulator {
  final String month;
  final DateTime sortKey;

  int totalCount = 0;
  int paidCount = 0;
  int unpaidCount = 0;
  int overdueCount = 0;
  double totalAmount = 0;
  double paidAmount = 0;
  double unpaidAmount = 0;

  _MonthlyAccumulator({required this.month, required this.sortKey});

  void add(
    DueEntity due, {
    required DateTime? dueDate,
    required DateTime today,
    required bool isSettled,
  }) {
    totalCount += 1;
    totalAmount += due.amount;
    if (due.paid) {
      paidCount += 1;
      paidAmount += due.amount;
    }
    if (!isSettled) {
      unpaidCount += 1;
      unpaidAmount += due.amount;
    }

    if (dueDate != null) {
      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (dueDay.isBefore(today) && !isSettled) {
        overdueCount += 1;
      }
    }
  }
}
