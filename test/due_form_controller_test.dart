import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/data/models/due_model.dart';
import 'package:myduesapp/features/dues/domain/usecases/create_due.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';

class MockCreateDue extends Mock implements CreateDue {}
class MockGetPaymentDates extends Mock implements GetPaymentDates {}

void main() {
  late DueFormController controller;
  late MockCreateDue mockCreateDue;
  late MockGetPaymentDates mockGetPaymentDates;

  setUpAll(() {
    registerFallbackValue(DueModel(
      id: 0,
      name: '',
      amount: 0.0,
      paid: false,
      dayOfMonth: 0,
      recurring: false,
      recurringInterval: 1,
      createdAt: '',
      updatedAt: '',
    ));
  });

  setUp(() {
    mockCreateDue = MockCreateDue();
    mockGetPaymentDates = MockGetPaymentDates();
    controller = DueFormController(
      getPaymentDates: mockGetPaymentDates,
      createDueUseCase: mockCreateDue,
    );
  });

  test('should initialize with correct values', () {
    expect(controller.isLoading, equals(false));
    expect(controller.errorMessage, isNull);
  });

  test('should set loading state when creating due', () async {
    // Arrange
    when(() => mockCreateDue(any()))
        .thenAnswer((_) async => Future.delayed(const Duration(milliseconds: 10)));

    // Act
    final due = DueModel(
      id: 1,
      name: 'Test Due',
      amount: 100.0,
      paid: false,
      dayOfMonth: 15,
      recurring: false,
      recurringInterval: 1,
      createdAt: '2023-09-15 10:00:00',
      updatedAt: '2023-09-15 10:00:00',
    );
    controller.createDue(due);

    // Assert
    expect(controller.isLoading, equals(true));
    verify(() => mockCreateDue(due)).called(1);
  });

  test('should reset loading state after creating due', () async {
    // Arrange
    when(() => mockCreateDue(any()))
        .thenAnswer((_) async => Future.value());

    // Act
    final due = DueModel(
      id: 1,
      name: 'Test Due',
      amount: 100.0,
      paid: false,
      dayOfMonth: 15,
      recurring: false,
      recurringInterval: 1,
      createdAt: '2023-09-15 10:00:00',
      updatedAt: '2023-09-15 10:00:00',
    );
    await controller.createDue(due);

    // Assert
    expect(controller.isLoading, equals(false));
    verify(() => mockCreateDue(due)).called(1);
  });

  test('should handle error when creating due fails', () async {
    // Arrange
    when(() => mockCreateDue(any()))
        .thenThrow(Exception('Failed to create due'));

    // Act
    final due = DueModel(
      id: 1,
      name: 'Test Due',
      amount: 100.0,
      paid: false,
      dayOfMonth: 15,
      recurring: false,
      recurringInterval: 1,
      createdAt: '2023-09-15 10:00:00',
      updatedAt: '2023-09-15 10:00:00',
    );
    await controller.createDue(due);

    // Assert
    expect(controller.isLoading, equals(false));
    expect(controller.errorMessage, equals('Exception: Failed to create due'));
    verify(() => mockCreateDue(due)).called(1);
  });
}