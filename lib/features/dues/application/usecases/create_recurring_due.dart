import 'dart:math';

import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class CreateRecurringDue {
  final DueRepository repository;

  CreateRecurringDue({required this.repository});

  Future<void> call({
    required String name,
    required double amount,
    required int billingDay,
    required int recurringInterval,
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

    final nowIso = DateTime.now().toIso8601String();
    final template = RecurringTemplateEntity(
      id: _buildRecurringTemplateId(),
      name: cleanName,
      amount: amount,
      billingDay: billingDay,
      intervalMonths: recurringInterval,
      startDate: (startDate ?? DateTime.now()).toIso8601String(),
      active: true,
      createdAt: nowIso,
      updatedAt: nowIso,
    );
    await repository.createRecurringTemplate(template);
  }

  String _buildRecurringTemplateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(1 << 20);
    return 'recurring_template_${now}_$rand';
  }
}
