import 'dart:math';

import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class CreateRecurringDue {
  final DueRepository repository;

  CreateRecurringDue({required this.repository});

  Future<void> call({
    required String name,
    required double amount,
    required int billingDay,
    required int recurringInterval,
    required int occurrenceCount,
    DateTime? startDate,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Name is required');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero');
    }
    if (billingDay < 1 || billingDay > 31) {
      throw ArgumentError('Billing day must be between 1 and 31');
    }
    if (recurringInterval < 1) {
      throw ArgumentError('Recurring interval must be at least 1 month');
    }
    if (occurrenceCount < 1) {
      throw ArgumentError('Occurrence count must be at least 1');
    }
    if (occurrenceCount > 120) {
      throw ArgumentError('Occurrence count must be 120 or less');
    }

    final firstDate = _nextDueDate(startDate ?? DateTime.now(), billingDay);
    final recurringGroupId = _buildRecurringGroupId();
    final dues = <DueEntity>[];

    for (var i = 0; i < occurrenceCount; i++) {
      final month = DateTime(
        firstDate.year,
        firstDate.month + (i * recurringInterval),
        1,
      );
      final dueDate = _dateForBillingDay(
        year: month.year,
        month: month.month,
        billingDay: billingDay,
      );

      dues.add(
        DueEntity(
          name: cleanName,
          amount: amount,
          recurring: true,
          recurringInterval: recurringInterval,
          dayOfMonth: billingDay,
          loanId: recurringGroupId,
          dueDate: dueDate.toIso8601String(),
          paid: false,
          complete: false,
        ),
      );
    }

    await repository.createDues(dues);
  }

  String _buildRecurringGroupId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 20);
    return 'recurring_${now}_$rand';
  }

  DateTime _nextDueDate(DateTime from, int billingDay) {
    final dateOnly = DateTime(from.year, from.month, from.day);
    var monthCursor = DateTime(from.year, from.month, 1);

    while (true) {
      final candidate = _dateForBillingDay(
        year: monthCursor.year,
        month: monthCursor.month,
        billingDay: billingDay,
      );
      if (!candidate.isBefore(dateOnly)) {
        return candidate;
      }
      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }
  }

  DateTime _dateForBillingDay({
    required int year,
    required int month,
    required int billingDay,
  }) {
    final maxDay = DateTime(year, month + 1, 0).day;
    final clampedDay = billingDay > maxDay ? maxDay : billingDay;
    return DateTime(year, month, clampedDay);
  }
}
