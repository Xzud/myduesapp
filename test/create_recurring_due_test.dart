import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/create_recurring_due.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  late CreateRecurringDue usecase;
  late MockDueRepository mockDueRepository;

  setUpAll(() {
    registerFallbackValue(<DueEntity>[
      const DueEntity(name: '', amount: 0, dayOfMonth: 1),
    ]);
  });

  setUp(() {
    mockDueRepository = MockDueRepository();
    usecase = CreateRecurringDue(repository: mockDueRepository);
  });

  test(
    'should create monthly recurring dues and clamp month-end dates',
    () async {
      when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

      await usecase.call(
        name: 'Rent',
        amount: 12000,
        billingDay: 31,
        recurringInterval: 1,
        occurrenceCount: 3,
        startDate: DateTime(2024, 1, 30),
      );

      final captured =
          verify(
                () => mockDueRepository.createDues(captureAny()),
              ).captured.single
              as List<DueEntity>;

      expect(captured, hasLength(3));
      expect(captured.map((due) => due.dueDate), [
        '2024-01-31T00:00:00.000',
        '2024-02-29T00:00:00.000',
        '2024-03-31T00:00:00.000',
      ]);
      expect(captured.map((due) => due.dayOfMonth), [31, 31, 31]);
      expect(captured.map((due) => due.recurring), [true, true, true]);
      expect(captured.map((due) => due.recurringInterval), [1, 1, 1]);
      expect(captured.map((due) => due.amount), [12000, 12000, 12000]);
    },
  );

  test('should space recurring dues by the configured interval', () async {
    when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

    await usecase.call(
      name: 'Insurance',
      amount: 2500,
      billingDay: 5,
      recurringInterval: 2,
      occurrenceCount: 3,
      startDate: DateTime(2024, 1, 1),
    );

    final captured =
        verify(() => mockDueRepository.createDues(captureAny())).captured.single
            as List<DueEntity>;

    expect(captured.map((due) => due.dueDate), [
      '2024-01-05T00:00:00.000',
      '2024-03-05T00:00:00.000',
      '2024-05-05T00:00:00.000',
    ]);
    expect(captured.map((due) => due.recurringInterval), [2, 2, 2]);
  });

  test(
    'should start in the next month when billing day already passed',
    () async {
      when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

      await usecase.call(
        name: 'Internet',
        amount: 1800,
        billingDay: 15,
        recurringInterval: 1,
        occurrenceCount: 2,
        startDate: DateTime(2024, 1, 20),
      );

      final captured =
          verify(
                () => mockDueRepository.createDues(captureAny()),
              ).captured.single
              as List<DueEntity>;

      expect(captured.map((due) => due.dueDate), [
        '2024-02-15T00:00:00.000',
        '2024-03-15T00:00:00.000',
      ]);
    },
  );

  test('should reject invalid recurring due values', () async {
    await expectLater(
      () => usecase.call(
        name: '',
        amount: 1200,
        billingDay: 15,
        recurringInterval: 1,
        occurrenceCount: 12,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => usecase.call(
        name: 'Rent',
        amount: 0,
        billingDay: 15,
        recurringInterval: 1,
        occurrenceCount: 12,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => usecase.call(
        name: 'Rent',
        amount: 1200,
        billingDay: 32,
        recurringInterval: 1,
        occurrenceCount: 12,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => usecase.call(
        name: 'Rent',
        amount: 1200,
        billingDay: 15,
        recurringInterval: 0,
        occurrenceCount: 12,
      ),
      throwsArgumentError,
    );
    await expectLater(
      () => usecase.call(
        name: 'Rent',
        amount: 1200,
        billingDay: 15,
        recurringInterval: 1,
        occurrenceCount: 121,
      ),
      throwsArgumentError,
    );
  });
}
