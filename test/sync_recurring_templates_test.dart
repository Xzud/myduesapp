import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/generate_recurring_occurrences.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_recurring_templates.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  late MockDueRepository mockDueRepository;
  late SyncRecurringTemplates usecase;
  late List<DueEntity> duesState;
  late List<RecurringTemplateEntity> templateState;

  setUpAll(() {
    registerFallbackValue(
      const DueEntity(id: 0, name: '', amount: 0, dayOfMonth: 1),
    );
    registerFallbackValue(<DueEntity>[]);
    registerFallbackValue(
      const RecurringTemplateEntity(
        id: 'template',
        name: '',
        amount: 0,
        billingDay: 1,
        intervalMonths: 1,
        startDate: '2026-01-01T00:00:00.000',
      ),
    );
  });

  setUp(() {
    mockDueRepository = MockDueRepository();
    duesState = [
      const DueEntity(
        id: 1,
        name: 'Internet',
        amount: 1800,
        recurring: true,
        recurringInterval: 1,
        dayOfMonth: 15,
        loanId: 'legacy-recurring-1',
        dueDate: '2026-06-15T00:00:00.000',
        createdAt: '2026-06-01T10:00:00.000',
      ),
      const DueEntity(
        id: 2,
        name: 'Internet',
        amount: 1800,
        recurring: true,
        recurringInterval: 1,
        dayOfMonth: 15,
        loanId: 'legacy-recurring-1',
        dueDate: '2026-07-15T00:00:00.000',
        createdAt: '2026-06-01T10:00:00.000',
      ),
    ];
    templateState = [];

    when(() => mockDueRepository.getDues()).thenAnswer((_) async => duesState);
    when(
      () => mockDueRepository.getRecurringTemplates(),
    ).thenAnswer((_) async => templateState);
    when(() => mockDueRepository.createRecurringTemplate(any())).thenAnswer((
      invocation,
    ) async {
      templateState = [
        ...templateState,
        invocation.positionalArguments.first as RecurringTemplateEntity,
      ];
    });
    when(() => mockDueRepository.updateDue(any())).thenAnswer((
      invocation,
    ) async {
      final updated = invocation.positionalArguments.first as DueEntity;
      duesState = [
        for (final due in duesState)
          if (due.id == updated.id) updated else due,
      ];
    });
    when(() => mockDueRepository.createDues(any())).thenAnswer((
      invocation,
    ) async {
      final created = invocation.positionalArguments.first as List<DueEntity>;
      final nextId = duesState.fold<int>(
        0,
        (maxId, due) => due.id != null && due.id! > maxId ? due.id! : maxId,
      );
      duesState = [
        ...duesState,
        for (var i = 0; i < created.length; i++)
          DueEntity(
            id: nextId + i + 1,
            name: created[i].name,
            amount: created[i].amount,
            recurring: created[i].recurring,
            recurringInterval: created[i].recurringInterval,
            recurringTemplateId: created[i].recurringTemplateId,
            generatedFromTemplate: created[i].generatedFromTemplate,
            dayOfMonth: created[i].dayOfMonth,
            loanId: created[i].loanId,
            installmentIndex: created[i].installmentIndex,
            installmentCount: created[i].installmentCount,
            dueDate: created[i].dueDate,
            paid: created[i].paid,
            complete: created[i].complete,
            createdAt: created[i].createdAt,
            updatedAt: created[i].updatedAt,
          ),
      ];
    });

    usecase = SyncRecurringTemplates(
      repository: mockDueRepository,
      generateRecurringOccurrences: GenerateRecurringOccurrences(),
      now: () => DateTime(2026, 6, 10),
    );
  });

  test(
    'should migrate legacy recurring dues into an active template',
    () async {
      final changed = await usecase.call();

      expect(changed, isTrue);
      expect(templateState, hasLength(1));
      expect(templateState.single.id, 'legacy_template_legacy-recurring-1');
      expect(templateState.single.active, isTrue);
      expect(
        duesState.every(
          (due) =>
              due.recurringTemplateId == 'legacy_template_legacy-recurring-1',
        ),
        isTrue,
      );
      expect(duesState.every((due) => due.generatedFromTemplate), isTrue);
      expect(duesState.length, greaterThan(2));
    },
  );

  test('should not generate duplicate occurrences on repeated sync', () async {
    await usecase.call();
    final dueDatesAfterFirstRun = duesState.map((due) => due.dueDate).toList();

    final changed = await usecase.call();

    expect(changed, isFalse);
    expect(duesState.map((due) => due.dueDate).toList(), dueDatesAfterFirstRun);
  });
}
