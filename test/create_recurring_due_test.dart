import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/create_recurring_due.dart';
import 'package:myduesapp/features/dues/domain/entities/recurring_template_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  late CreateRecurringDue usecase;
  late MockDueRepository mockDueRepository;

  setUpAll(() {
    registerFallbackValue(
      const RecurringTemplateEntity(
        id: 'template',
        name: 'Name',
        amount: 1,
        billingDay: 1,
        intervalMonths: 1,
        startDate: '2026-01-01T00:00:00.000',
      ),
    );
  });

  setUp(() {
    mockDueRepository = MockDueRepository();
    when(
      () => mockDueRepository.createRecurringTemplate(any()),
    ).thenAnswer((_) async {});
    usecase = CreateRecurringDue(repository: mockDueRepository);
  });

  test('should create a recurring template with validated fields', () async {
    final startDate = DateTime(2026, 6, 12);

    await usecase.call(
      name: ' Internet ',
      amount: 1800,
      billingDay: 15,
      recurringInterval: 2,
      startDate: startDate,
    );

    final captured =
        verify(
              () => mockDueRepository.createRecurringTemplate(captureAny()),
            ).captured.single
            as RecurringTemplateEntity;

    expect(captured.id, startsWith('recurring_template_'));
    expect(captured.name, 'Internet');
    expect(captured.amount, 1800);
    expect(captured.billingDay, 15);
    expect(captured.intervalMonths, 2);
    expect(captured.startDate, startDate.toIso8601String());
    expect(captured.active, isTrue);
  });

  test('should default template start date to now when omitted', () async {
    await usecase.call(
      name: 'Rent',
      amount: 12000,
      billingDay: 31,
      recurringInterval: 1,
    );

    final captured =
        verify(
              () => mockDueRepository.createRecurringTemplate(captureAny()),
            ).captured.single
            as RecurringTemplateEntity;

    expect(DateTime.tryParse(captured.startDate), isNotNull);
  });

  test('should reject invalid recurring template values', () async {
    await expectLater(
      () => usecase.call(
        name: '',
        amount: 1200,
        billingDay: 15,
        recurringInterval: 1,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => usecase.call(
        name: 'Rent',
        amount: 0,
        billingDay: 15,
        recurringInterval: 1,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => usecase.call(
        name: 'Rent',
        amount: 1200,
        billingDay: 32,
        recurringInterval: 1,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => usecase.call(
        name: 'Rent',
        amount: 1200,
        billingDay: 15,
        recurringInterval: 0,
      ),
      throwsArgumentError,
    );
  });
}
