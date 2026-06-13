import 'package:myduesapp/features/dues/application/usecases/generate_recurring_occurrences.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class SyncRecurringTemplates {
  final DueRepository repository;
  final GenerateRecurringOccurrences generateRecurringOccurrences;
  final DateTime Function() now;

  SyncRecurringTemplates({
    required this.repository,
    required this.generateRecurringOccurrences,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<bool> call({String? templateId}) async {
    var changed = false;
    var dues = await repository.getDues();
    var templates = await repository.getRecurringTemplates();

    final migrated = await _migrateLegacyRecurringGroups(
      dues: dues,
      templates: templates,
      templateId: templateId,
    );
    changed = changed || migrated;

    if (migrated) {
      dues = await repository.getDues();
      templates = await repository.getRecurringTemplates();
    }

    final activeTemplates = templates.where((template) => template.active);
    for (final template in activeTemplates) {
      if (templateId != null && template.id != templateId) {
        continue;
      }

      final existing = dues
          .where((due) => due.recurringTemplateId == template.id)
          .toList();
      final generated = generateRecurringOccurrences.call(
        template: template,
        existingDues: existing,
        referenceDate: now(),
      );
      if (generated.isEmpty) {
        continue;
      }

      await repository.createDues(generated);
      dues = [...dues, ...generated];
      changed = true;
    }

    return changed;
  }

  Future<bool> _migrateLegacyRecurringGroups({
    required List<DueEntity> dues,
    required List<RecurringTemplateEntity> templates,
    required String? templateId,
  }) async {
    final legacyGroups = <String, List<DueEntity>>{};
    for (final due in dues) {
      if (!due.recurring) {
        continue;
      }
      final existingTemplateId = due.recurringTemplateId?.trim();
      if (existingTemplateId != null && existingTemplateId.isNotEmpty) {
        continue;
      }

      final groupKey = _legacyGroupKey(due);
      legacyGroups.putIfAbsent(groupKey, () => []).add(due);
    }

    if (legacyGroups.isEmpty) {
      return false;
    }

    final templateIds = templates.map((template) => template.id).toSet();
    var changed = false;

    for (final entry in legacyGroups.entries) {
      final group = [...entry.value]..sort(_compareDues);
      final inferredTemplateId = _legacyTemplateId(group);
      if (templateId != null && inferredTemplateId != templateId) {
        continue;
      }

      if (!templateIds.contains(inferredTemplateId)) {
        final template = _templateFromLegacyGroup(
          templateId: inferredTemplateId,
          dues: group,
        );
        await repository.createRecurringTemplate(template);
        templateIds.add(inferredTemplateId);
        changed = true;
      }

      for (final due in group) {
        final updated = DueEntity(
          id: due.id,
          name: due.name,
          amount: due.amount,
          recurring: due.recurring,
          recurringInterval: due.recurringInterval,
          recurringTemplateId: inferredTemplateId,
          generatedFromTemplate: true,
          dayOfMonth: due.dayOfMonth,
          loanId: due.loanId,
          installmentIndex: due.installmentIndex,
          installmentCount: due.installmentCount,
          dueDate: due.dueDate,
          paid: due.paid,
          complete: due.complete,
          createdAt: due.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await repository.updateDue(updated);
        changed = true;
      }
    }

    return changed;
  }

  RecurringTemplateEntity _templateFromLegacyGroup({
    required String templateId,
    required List<DueEntity> dues,
  }) {
    final sorted = [...dues]..sort(_compareDues);
    final first = sorted.first;
    final latest = sorted.last;
    final startDate =
        first.dueDate ?? first.createdAt ?? DateTime.now().toIso8601String();
    final billingDay = _billingDayFor(latest);
    final intervalMonths = latest.recurringInterval < 1
        ? 1
        : latest.recurringInterval;

    return RecurringTemplateEntity(
      id: templateId,
      name: latest.name.trim().isEmpty ? first.name : latest.name,
      amount: latest.amount > 0 ? latest.amount : first.amount,
      billingDay: billingDay,
      intervalMonths: intervalMonths,
      startDate: startDate,
      active: true,
      createdAt: first.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  int _billingDayFor(DueEntity due) {
    if (due.dayOfMonth >= 1 && due.dayOfMonth <= 31) {
      return due.dayOfMonth;
    }
    final parsed = DateTime.tryParse(due.dueDate ?? '');
    return parsed?.day ?? 1;
  }

  String _legacyGroupKey(DueEntity due) {
    final loanId = due.loanId?.trim();
    if (loanId != null && loanId.isNotEmpty) {
      return 'loan:$loanId';
    }

    final createdAt = due.createdAt?.trim() ?? '';
    return [
      due.name.trim().toLowerCase(),
      due.amount.toStringAsFixed(2),
      _billingDayFor(due).toString(),
      due.recurringInterval.toString(),
      createdAt,
    ].join('|');
  }

  String _legacyTemplateId(List<DueEntity> dues) {
    final first = dues.first;
    final loanId = first.loanId?.trim();
    if (loanId != null && loanId.isNotEmpty) {
      return 'legacy_template_$loanId';
    }

    return 'legacy_template_due_${first.id ?? first.hashCode}';
  }

  int _compareDues(DueEntity a, DueEntity b) {
    final ad =
        DateTime.tryParse(a.dueDate ?? '') ??
        DateTime.tryParse(a.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bd =
        DateTime.tryParse(b.dueDate ?? '') ??
        DateTime.tryParse(b.createdAt ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final dateCompare = ad.compareTo(bd);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }
}
