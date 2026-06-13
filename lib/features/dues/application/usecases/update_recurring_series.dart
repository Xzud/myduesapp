import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class UpdateRecurringSeries {
  final DueRepository repository;
  final DateTime Function() now;

  UpdateRecurringSeries({required this.repository, DateTime Function()? now})
    : now = now ?? DateTime.now;

  Future<void> call({
    required String templateId,
    required String name,
    required double amount,
    required int billingDay,
    required int intervalMonths,
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
    if (intervalMonths < 1) {
      throw ArgumentError('Recurring interval must be at least 1 month');
    }

    final templates = await repository.getRecurringTemplates();
    final template = _findTemplate(templates, templateId);
    final dues = await repository.getDues();
    final boundary = _boundaryDate(dues, templateId);
    final updatedTemplate = template.copyWith(
      name: cleanName,
      amount: amount,
      billingDay: billingDay,
      intervalMonths: intervalMonths,
      startDate: boundary.toIso8601String(),
      active: true,
      updatedAt: now().toIso8601String(),
    );

    await repository.updateRecurringTemplate(updatedTemplate);

    final boundaryDate = DateTime(boundary.year, boundary.month, boundary.day);
    final idsToDelete = dues
        .where((due) => due.recurringTemplateId == templateId)
        .where((due) => due.generatedFromTemplate && !due.paid)
        .where((due) {
          final parsed = DateTime.tryParse(due.dueDate ?? '');
          if (parsed == null || due.id == null) {
            return false;
          }
          final dueDate = DateTime(parsed.year, parsed.month, parsed.day);
          return !dueDate.isBefore(boundaryDate);
        })
        .map((due) => due.id!)
        .toList();

    if (idsToDelete.isNotEmpty) {
      await repository.deleteDues(idsToDelete);
    }
  }

  RecurringTemplateEntity _findTemplate(
    List<RecurringTemplateEntity> templates,
    String templateId,
  ) {
    for (final template in templates) {
      if (template.id == templateId) {
        return template;
      }
    }

    throw StateError('Recurring template not found');
  }

  DateTime _boundaryDate(List<DueEntity> dues, String templateId) {
    final today = now();
    final todayDate = DateTime(today.year, today.month, today.day);
    DateTime? earliestUpcoming;

    for (final due in dues) {
      if (due.recurringTemplateId != templateId || due.paid) {
        continue;
      }
      final parsed = DateTime.tryParse(due.dueDate ?? '');
      if (parsed == null) {
        continue;
      }
      final dueDate = DateTime(parsed.year, parsed.month, parsed.day);
      if (dueDate.isBefore(todayDate)) {
        continue;
      }
      if (earliestUpcoming == null || dueDate.isBefore(earliestUpcoming)) {
        earliestUpcoming = dueDate;
      }
    }

    return earliestUpcoming ?? todayDate;
  }
}
