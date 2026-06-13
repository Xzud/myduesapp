import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';

class GenerateRecurringOccurrences {
  static const int materializedUnpaidOccurrenceCount = 6;

  List<DueEntity> call({
    required RecurringTemplateEntity template,
    required List<DueEntity> existingDues,
    DateTime? referenceDate,
  }) {
    if (!template.active) {
      return const [];
    }

    final now = _dateOnly(referenceDate ?? DateTime.now());
    final existingDueKeys = <String>{};
    var upcomingUnpaidCount = 0;

    for (final due in existingDues) {
      final parsed = _parseDate(due.dueDate);
      if (parsed == null) {
        continue;
      }

      final key = _dateKey(parsed);
      existingDueKeys.add(key);
      if (!due.paid && !_dateOnly(parsed).isBefore(now)) {
        upcomingUnpaidCount += 1;
      }
    }

    if (upcomingUnpaidCount >= materializedUnpaidOccurrenceCount) {
      return const [];
    }

    final start = _parseDate(template.startDate) ?? now;
    final firstCandidate = _nextDueDate(start, template.billingDay);
    final created = <DueEntity>[];
    final createdKeys = <String>{};
    final nowIso = DateTime.now().toIso8601String();

    for (var i = 0; i < 240; i++) {
      if (upcomingUnpaidCount + created.length >=
          materializedUnpaidOccurrenceCount) {
        break;
      }

      final month = DateTime(
        firstCandidate.year,
        firstCandidate.month + (i * template.intervalMonths),
        1,
      );
      final candidate = _dateForBillingDay(
        year: month.year,
        month: month.month,
        billingDay: template.billingDay,
      );
      final candidateDate = _dateOnly(candidate);
      if (candidateDate.isBefore(now)) {
        continue;
      }

      final candidateKey = _dateKey(candidateDate);
      if (existingDueKeys.contains(candidateKey) ||
          createdKeys.contains(candidateKey)) {
        continue;
      }

      createdKeys.add(candidateKey);
      created.add(
        DueEntity(
          name: template.name,
          amount: template.amount,
          recurring: true,
          recurringInterval: template.intervalMonths,
          recurringTemplateId: template.id,
          generatedFromTemplate: true,
          dayOfMonth: template.billingDay,
          dueDate: candidateDate.toIso8601String(),
          paid: false,
          complete: false,
          createdAt: nowIso,
          updatedAt: nowIso,
        ),
      );
    }

    return created;
  }

  DateTime _nextDueDate(DateTime from, int billingDay) {
    final dateOnly = _dateOnly(from);
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

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dateKey(DateTime value) {
    final normalized = _dateOnly(value);
    return normalized.toIso8601String();
  }
}
