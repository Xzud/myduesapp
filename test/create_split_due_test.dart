import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/create_split_due.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/entities/interest_plan.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  late CreateSplitDue usecase;
  late MockDueRepository mockDueRepository;

  setUpAll(() {
    registerFallbackValue(<DueEntity>[
      const DueEntity(name: '', amount: 0, dayOfMonth: 1),
    ]);
  });

  setUp(() {
    mockDueRepository = MockDueRepository();
    usecase = CreateSplitDue(repository: mockDueRepository);
  });

  test(
    'should populate each installment on the same billing day when single day is selected',
    () async {
      when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

      await usecase.call(
        name: 'Loan A',
        amount: 3000,
        installmentCount: 3,
        billingDays: [7],
        startDate: DateTime(2024, 1, 1),
      );

      final captured =
          verify(
                () => mockDueRepository.createDues(captureAny()),
              ).captured.single
              as List<DueEntity>;

      expect(captured, hasLength(3));
      expect(captured.map((due) => due.dueDate), [
        '2024-01-07T00:00:00.000',
        '2024-02-07T00:00:00.000',
        '2024-03-07T00:00:00.000',
      ]);
      expect(captured.map((due) => due.dayOfMonth), [7, 7, 7]);
    },
  );

  test(
    'should populate on each selected billing day when multiple days are selected',
    () async {
      when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

      await usecase.call(
        name: 'Loan A',
        amount: 3000,
        installmentCount: 3,
        billingDays: [7, 15],
        startDate: DateTime(2024, 1, 1),
      );

      final captured =
          verify(
                () => mockDueRepository.createDues(captureAny()),
              ).captured.single
              as List<DueEntity>;

      expect(captured, hasLength(3));
      expect(captured.map((due) => due.dueDate), [
        '2024-01-07T00:00:00.000',
        '2024-01-15T00:00:00.000',
        '2024-02-07T00:00:00.000',
      ]);
      expect(captured.map((due) => due.dayOfMonth), [7, 15, 7]);
    },
  );

  test(
    'should add percentage interest before splitting installments',
    () async {
      when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

      await usecase.call(
        name: 'Loan A',
        amount: 3000,
        installmentCount: 3,
        billingDays: [7],
        startDate: DateTime(2024, 1, 1),
        interestPlan: const InterestPlan(
          mode: InterestMode.percentage,
          value: 10,
        ),
      );

      final captured =
          verify(
                () => mockDueRepository.createDues(captureAny()),
              ).captured.single
              as List<DueEntity>;

      expect(captured.map((due) => due.amount), [1100, 1100, 1100]);
    },
  );

  test('should add monthly fixed interest to each installment', () async {
    when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

    await usecase.call(
      name: 'Loan A',
      amount: 3000,
      installmentCount: 3,
      billingDays: [7],
      startDate: DateTime(2024, 1, 1),
      interestPlan: const InterestPlan(
        mode: InterestMode.monthlyFixedAmount,
        value: 50,
      ),
    );

    final captured =
        verify(() => mockDueRepository.createDues(captureAny())).captured.single
            as List<DueEntity>;

    expect(captured.map((due) => due.amount), [1050, 1050, 1050]);
  });

  test('should divide a total interest amount across installments', () async {
    when(() => mockDueRepository.createDues(any())).thenAnswer((_) async {});

    await usecase.call(
      name: 'Loan A',
      amount: 3000,
      installmentCount: 3,
      billingDays: [7],
      startDate: DateTime(2024, 1, 1),
      interestPlan: const InterestPlan(
        mode: InterestMode.totalAmountDividedPerMonth,
        value: 100,
      ),
    );

    final captured =
        verify(() => mockDueRepository.createDues(captureAny())).captured.single
            as List<DueEntity>;

    expect(captured.map((due) => due.amount), [1033.33, 1033.33, 1033.34]);
  });

  test('should reject invalid interest values', () async {
    await expectLater(
      () => usecase.call(
        name: 'Loan A',
        amount: 3000,
        installmentCount: 3,
        billingDays: [7],
        interestPlan: const InterestPlan(
          mode: InterestMode.percentage,
          value: 0,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('should reject invalid billing day selections', () async {
    await expectLater(
      () => usecase.call(
        name: 'Loan A',
        amount: 3000,
        installmentCount: 3,
        billingDays: const [],
      ),
      throwsArgumentError,
    );
  });
}
