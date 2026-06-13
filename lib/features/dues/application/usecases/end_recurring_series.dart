import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class EndRecurringSeries {
  final DueRepository repository;
  final DateTime Function() now;

  EndRecurringSeries({required this.repository, DateTime Function()? now})
    : now = now ?? DateTime.now;

  Future<void> call(String templateId) async {
    final templates = await repository.getRecurringTemplates();
    final template = templates.firstWhere(
      (item) => item.id == templateId,
      orElse: () => throw StateError('Recurring template not found'),
    );

    await repository.updateRecurringTemplate(
      template.copyWith(active: false, updatedAt: now().toIso8601String()),
    );

    final today = now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dues = await repository.getDues();
    final idsToDelete = dues
        .where((due) => due.recurringTemplateId == templateId)
        .where((due) => due.generatedFromTemplate && !due.paid)
        .where((due) {
          final parsed = DateTime.tryParse(due.dueDate ?? '');
          if (parsed == null || due.id == null) {
            return false;
          }
          final dueDate = DateTime(parsed.year, parsed.month, parsed.day);
          return dueDate.isAfter(todayDate);
        })
        .map((due) => due.id!)
        .toList();

    if (idsToDelete.isNotEmpty) {
      await repository.deleteDues(idsToDelete);
    }
  }
}
