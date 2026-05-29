import 'package:equatable/equatable.dart';

class DashboardMonthlySummary extends Equatable {
  final String month;
  final int totalCount;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final double totalAmount;
  final double paidAmount;
  final double unpaidAmount;

  const DashboardMonthlySummary({
    required this.month,
    required this.totalCount,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidAmount,
  });

  @override
  List<Object?> get props => [
    month,
    totalCount,
    paidCount,
    unpaidCount,
    overdueCount,
    totalAmount,
    paidAmount,
    unpaidAmount,
  ];

  @override
  bool get stringify => true;
}

class DashboardSummary extends Equatable {
  final int totalCount;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final int dueTodayCount;
  final int upcomingCount;
  final int recurringCount;
  final int oneTimeCount;
  final int completeCount;
  final double totalAmount;
  final double paidAmount;
  final double unpaidAmount;
  final double overdueAmount;
  final List<DashboardMonthlySummary> monthlySummaries;

  const DashboardSummary({
    required this.totalCount,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.upcomingCount,
    required this.recurringCount,
    required this.oneTimeCount,
    required this.completeCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.overdueAmount,
    required this.monthlySummaries,
  });

  const DashboardSummary.empty()
    : totalCount = 0,
      paidCount = 0,
      unpaidCount = 0,
      overdueCount = 0,
      dueTodayCount = 0,
      upcomingCount = 0,
      recurringCount = 0,
      oneTimeCount = 0,
      completeCount = 0,
      totalAmount = 0,
      paidAmount = 0,
      unpaidAmount = 0,
      overdueAmount = 0,
      monthlySummaries = const [];

  @override
  List<Object?> get props => [
    totalCount,
    paidCount,
    unpaidCount,
    overdueCount,
    dueTodayCount,
    upcomingCount,
    recurringCount,
    oneTimeCount,
    completeCount,
    totalAmount,
    paidAmount,
    unpaidAmount,
    overdueAmount,
    monthlySummaries,
  ];

  @override
  bool get stringify => true;
}
