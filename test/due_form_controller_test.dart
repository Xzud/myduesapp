import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/create_recurring_due.dart';
import 'package:myduesapp/features/dues/application/usecases/create_split_due.dart';
import 'package:myduesapp/features/dues/application/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/domain/entities/interest_plan.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';

class MockCreateSplitDue extends Mock implements CreateSplitDue {}

class MockCreateRecurringDue extends Mock implements CreateRecurringDue {}

class MockGetPaymentDates extends Mock implements GetPaymentDates {}

void main() {
  late DueFormController controller;
  late MockCreateSplitDue mockCreateSplitDue;
  late MockCreateRecurringDue mockCreateRecurringDue;
  late MockGetPaymentDates mockGetPaymentDates;

  setUp(() {
    mockCreateSplitDue = MockCreateSplitDue();
    mockCreateRecurringDue = MockCreateRecurringDue();
    mockGetPaymentDates = MockGetPaymentDates();
    controller = DueFormController(
      getPaymentDates: mockGetPaymentDates,
      createSplitDue: mockCreateSplitDue,
      createRecurringDue: mockCreateRecurringDue,
    );
  });

  test('initializes with default values', () {
    expect(controller.isLoading, false);
    expect(controller.errorMessage, isNull);
  });

  test('creates split loan successfully', () async {
    when(() => mockGetPaymentDates()).thenAnswer((_) async => ['5', '15']);
    when(
      () => mockCreateSplitDue(
        name: any(named: 'name'),
        amount: any(named: 'amount'),
        installmentCount: any(named: 'installmentCount'),
        billingDays: any(named: 'billingDays'),
        startDate: any(named: 'startDate'),
        interestPlan: any(named: 'interestPlan'),
      ),
    ).thenAnswer((_) async {});

    await controller.createLoanSplit(
      name: 'Loan A',
      amount: 5000,
      installmentCount: 3,
    );

    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, false);
    verify(() => mockGetPaymentDates()).called(1);
    verify(
      () => mockCreateSplitDue(
        name: 'Loan A',
        amount: 5000,
        installmentCount: 3,
        billingDays: [5, 15],
        startDate: null,
        interestPlan: null,
      ),
    ).called(1);
  });

  test('converts monthly amount to total when submitting split due', () async {
    when(
      () => mockCreateSplitDue(
        name: any(named: 'name'),
        amount: any(named: 'amount'),
        installmentCount: any(named: 'installmentCount'),
        billingDays: any(named: 'billingDays'),
        startDate: any(named: 'startDate'),
        interestPlan: any(named: 'interestPlan'),
      ),
    ).thenAnswer((_) async {});

    await controller.submitSplitDue(
      name: 'Loan A',
      inputAmount: 1000,
      installmentCount: 3,
      billingDays: [5, 15],
      amountMode: AmountInputMode.monthly,
    );

    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, false);
    verify(
      () => mockCreateSplitDue(
        name: 'Loan A',
        amount: 3000,
        installmentCount: 3,
        billingDays: [5, 15],
        startDate: null,
        interestPlan: null,
      ),
    ).called(1);
  });

  test('passes interest plan through when creating split loan', () async {
    when(() => mockGetPaymentDates()).thenAnswer((_) async => ['5']);
    when(
      () => mockCreateSplitDue(
        name: any(named: 'name'),
        amount: any(named: 'amount'),
        installmentCount: any(named: 'installmentCount'),
        billingDays: any(named: 'billingDays'),
        startDate: any(named: 'startDate'),
        interestPlan: any(named: 'interestPlan'),
      ),
    ).thenAnswer((_) async {});

    const interestPlan = InterestPlan(
      mode: InterestMode.totalAmountDividedPerMonth,
      value: 250,
    );

    await controller.createLoanSplit(
      name: 'Loan A',
      amount: 5000,
      installmentCount: 3,
      interestPlan: interestPlan,
    );

    verify(
      () => mockCreateSplitDue(
        name: 'Loan A',
        amount: 5000,
        installmentCount: 3,
        billingDays: [5],
        startDate: null,
        interestPlan: interestPlan,
      ),
    ).called(1);
  });

  test('stores error if split creation fails', () async {
    when(() => mockGetPaymentDates()).thenAnswer((_) async => ['5']);
    when(
      () => mockCreateSplitDue(
        name: any(named: 'name'),
        amount: any(named: 'amount'),
        installmentCount: any(named: 'installmentCount'),
        billingDays: any(named: 'billingDays'),
        startDate: any(named: 'startDate'),
        interestPlan: any(named: 'interestPlan'),
      ),
    ).thenThrow(Exception('Failed to create split'));

    await controller.createLoanSplit(
      name: 'Loan A',
      amount: 5000,
      installmentCount: 3,
    );

    expect(controller.isLoading, false);
    expect(controller.errorMessage, 'Exception: Failed to create split');
  });

  test('submits recurring due successfully', () async {
    when(
      () => mockCreateRecurringDue(
        name: any(named: 'name'),
        amount: any(named: 'amount'),
        billingDay: any(named: 'billingDay'),
        recurringInterval: any(named: 'recurringInterval'),
        occurrenceCount: any(named: 'occurrenceCount'),
        startDate: any(named: 'startDate'),
      ),
    ).thenAnswer((_) async {});

    final startDate = DateTime(2026, 6, 12);
    await controller.submitRecurringDue(
      name: 'Internet',
      inputAmount: 1800,
      billingDay: 15,
      recurringInterval: 1,
      occurrenceCount: 12,
      startDate: startDate,
    );

    expect(controller.errorMessage, isNull);
    expect(controller.isLoading, false);
    verify(
      () => mockCreateRecurringDue(
        name: 'Internet',
        amount: 1800,
        billingDay: 15,
        recurringInterval: 1,
        occurrenceCount: 12,
        startDate: startDate,
      ),
    ).called(1);
  });
}
