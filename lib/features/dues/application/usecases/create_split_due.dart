import 'dart:math';

import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class CreateSplitDue {
  final DueRepository repository;

  CreateSplitDue({required this.repository});

  Future<void> call({
    required String name,
    required double amount,
    required int installmentCount,
    required List<int> billingDays,
    DateTime? startDate,
  }) async {
    if (installmentCount < 1) {
      throw ArgumentError('Installment count must be at least 1');
    }
    if (billingDays.isEmpty) {
      throw ArgumentError('At least one billing day must be configured');
    }

    final cleanDays =
        billingDays.toSet().where((d) => d >= 1 && d <= 31).toList()..sort();
    if (cleanDays.isEmpty) {
      throw ArgumentError('Billing days must be between 1 and 31');
    }

    final loanId = _buildLoanId();
    final cents = (amount * 100).round();
    final base = cents ~/ installmentCount;
    final remainder = cents % installmentCount;

    final firstDate = startDate ?? DateTime.now();
    DateTime cursor = firstDate;
    final dues = <DueEntity>[];

    for (int i = 0; i < installmentCount; i++) {
      final dueDate = cleanDays.length == 1
          ? _nextDueDateForSingleBillingDay(cursor, cleanDays.single)
          : _nextDueDateForMultipleBillingDays(cursor, cleanDays);
      final installmentCents = i == installmentCount - 1
          ? base + remainder
          : base;

      dues.add(
        DueEntity(
          name: name,
          amount: installmentCents / 100,
          dayOfMonth: dueDate.day,
          loanId: loanId,
          installmentIndex: i + 1,
          installmentCount: installmentCount,
          dueDate: dueDate.toIso8601String(),
          paid: false,
          complete: false,
          recurring: false,
          recurringInterval: 0,
        ),
      );
      cursor = dueDate.add(const Duration(days: 1));
    }

    await repository.createDues(dues);
  }

  String _buildLoanId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 20);
    return 'loan_${now}_$rand';
  }

  DateTime _nextDueDateForSingleBillingDay(DateTime from, int billingDay) {
    final dateOnly = DateTime(from.year, from.month, from.day);
    var monthCursor = DateTime(from.year, from.month, 1);

    while (true) {
      final maxDay = DateTime(monthCursor.year, monthCursor.month + 1, 0).day;
      final clampedDay = billingDay > maxDay ? maxDay : billingDay;
      final candidate = DateTime(
        monthCursor.year,
        monthCursor.month,
        clampedDay,
      );
      if (!candidate.isBefore(dateOnly)) {
        return candidate;
      }
      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }
  }

  DateTime _nextDueDateForMultipleBillingDays(
    DateTime from,
    List<int> billingDays,
  ) {
    DateTime monthCursor = DateTime(from.year, from.month, 1);
    final dateOnly = DateTime(from.year, from.month, from.day);

    while (true) {
      for (final day in billingDays) {
        final maxDay = DateTime(monthCursor.year, monthCursor.month + 1, 0).day;
        final clampedDay = day > maxDay ? maxDay : day;
        final candidate = DateTime(
          monthCursor.year,
          monthCursor.month,
          clampedDay,
        );
        if (!candidate.isBefore(dateOnly)) {
          return candidate;
        }
      }
      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }
  }
}
