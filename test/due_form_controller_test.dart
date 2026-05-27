import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/domain/usecases/create_split_due.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';

class MockCreateSplitDue extends Mock implements CreateSplitDue {}

class MockGetPaymentDates extends Mock implements GetPaymentDates {}

void main() {
  late DueFormController controller;
  late MockCreateSplitDue mockCreateSplitDue;
  late MockGetPaymentDates mockGetPaymentDates;

  setUp(() {
    mockCreateSplitDue = MockCreateSplitDue();
    mockGetPaymentDates = MockGetPaymentDates();
    controller = DueFormController(
      getPaymentDates: mockGetPaymentDates,
      createSplitDue: mockCreateSplitDue,
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
}
