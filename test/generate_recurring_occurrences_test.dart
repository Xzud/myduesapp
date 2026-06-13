import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/application/usecases/generate_recurring_occurrences.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';

void main() {
  late GenerateRecurringOccurrences usecase;

  setUp(() {
    usecase = GenerateRecurringOccurrences();
  });

  test('should generate recurring dues and clamp month-end dates', () {
    const template = RecurringTemplateEntity(
      id: 'template-rent',
      name: 'Rent',
      amount: 12000,
      billingDay: 31,
      intervalMonths: 1,
      startDate: '2026-01-30T00:00:00.000',
    );

    final generated = usecase.call(
      template: template,
      existingDues: const [],
      referenceDate: DateTime(2026, 1, 30),
    );

    expect(generated.take(3).map((due) => due.dueDate), [
      '2026-01-31T00:00:00.000',
      '2026-02-28T00:00:00.000',
      '2026-03-31T00:00:00.000',
    ]);
    expect(
      generated,
      hasLength(GenerateRecurringOccurrences.materializedUnpaidOccurrenceCount),
    );
  });

  test('should space recurring dues by the configured interval', () {
    const template = RecurringTemplateEntity(
      id: 'template-insurance',
      name: 'Insurance',
      amount: 2500,
      billingDay: 5,
      intervalMonths: 2,
      startDate: '2026-01-01T00:00:00.000',
    );

    final generated = usecase.call(
      template: template,
      existingDues: const [],
      referenceDate: DateTime(2026, 1, 1),
    );

    expect(generated.take(3).map((due) => due.dueDate), [
      '2026-01-05T00:00:00.000',
      '2026-03-05T00:00:00.000',
      '2026-05-05T00:00:00.000',
    ]);
  });

  test(
    'should avoid duplicate creation when enough upcoming unpaid dues exist',
    () {
      const template = RecurringTemplateEntity(
        id: 'template-internet',
        name: 'Internet',
        amount: 1800,
        billingDay: 15,
        intervalMonths: 1,
        startDate: '2026-06-01T00:00:00.000',
      );

      final existing = List<DueEntity>.generate(
        GenerateRecurringOccurrences.materializedUnpaidOccurrenceCount,
        (index) => DueEntity(
          id: index + 1,
          name: 'Internet',
          amount: 1800,
          recurring: true,
          recurringInterval: 1,
          recurringTemplateId: 'template-internet',
          generatedFromTemplate: true,
          dayOfMonth: 15,
          dueDate: DateTime(2026, 6 + index, 15).toIso8601String(),
        ),
      );

      final generated = usecase.call(
        template: template,
        existingDues: existing,
        referenceDate: DateTime(2026, 6, 1),
      );

      expect(generated, isEmpty);
    },
  );
}
