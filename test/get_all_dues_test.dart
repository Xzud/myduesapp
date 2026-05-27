import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart';

class MockDueRepo extends Mock implements DueRepository {}

void main() {
  late GetAllDues getAllDues;
  late MockDueRepo mockDueRepo;

  setUp(() {
    mockDueRepo = MockDueRepo();
    getAllDues = GetAllDues(repository: mockDueRepo);
  });

  test('should return a list of dues from the repository', () async {
    // Arrange
    final mockDues = [
      DueEntity(
        id: 1,
        name: 'Electricity Bill',
        amount: 50.0,
        paid: false,
        dayOfMonth: 15,
        recurring: false,
        recurringInterval: 1,
        createdAt: '2023-09-15 10:00:00',
        updatedAt: '2023-09-15 10:00:00',
      ),
    ];
    when(() => mockDueRepo.getDues()).thenAnswer((_) async => mockDues);

    // Act
    final result = await getAllDues();

    // Assert
    expect(result, isNotEmpty);
    expect(result.length, equals(1));
    expect(result[0].month, equals('September 2023'));
    expect(result[0].dues, isNotEmpty);
    expect(result[0].dues.length, equals(1));
    expect(result[0].dues[0].name, equals('Electricity Bill'));
    expect(result[0].dues[0].price, equals(50.0));
    expect(result[0].dues[0].paid, equals(false));

    verify(() => mockDueRepo.getDues()).called(1);
  });

  test('should group dues by month correctly', () async {
    // Arrange
    final mockDues = [
      DueEntity(
        id: 1,
        name: 'Electricity Bill',
        amount: 50.0,
        paid: false,
        dayOfMonth: 15,
        recurring: false,
        recurringInterval: 1,
        createdAt: '2023-09-15 10:00:00',
        updatedAt: '2023-09-15 10:00:00',
      ),
      DueEntity(
        id: 2,
        name: 'Internet Bill',
        amount: 60.0,
        paid: true,
        dayOfMonth: 25,
        recurring: false,
        recurringInterval: 1,
        createdAt: '2023-09-25 14:30:00',
        updatedAt: '2023-09-25 14:30:00',
      ),
      DueEntity(
        id: 3,
        name: 'Rent Payment',
        amount: 1000.0,
        paid: false,
        dayOfMonth: 1,
        recurring: true,
        recurringInterval: 1,
        createdAt: '2023-10-01 09:00:00',
        updatedAt: '2023-10-01 09:00:00',
      ),
    ];
    when(() => mockDueRepo.getDues()).thenAnswer((_) async => mockDues);

    // Act
    final result = await getAllDues();

    // Assert
    expect(result, isNotEmpty);
    expect(result.length, equals(2)); // Two different months

    // Check September dues
    final septemberDues = result.firstWhere(
      (element) => element.month == 'September 2023',
    );
    expect(septemberDues.dues.length, equals(2));
    expect(septemberDues.dues[0].name, equals('Electricity Bill'));
    expect(septemberDues.dues[1].name, equals('Internet Bill'));

    // Check October dues
    final octoberDues = result.firstWhere(
      (element) => element.month == 'October 2023',
    );
    expect(octoberDues.dues.length, equals(1));
    expect(octoberDues.dues[0].name, equals('Rent Payment'));

    verify(() => mockDueRepo.getDues()).called(1);
  });

  test('should return empty list when no dues exist', () async {
    // Arrange
    when(() => mockDueRepo.getDues()).thenAnswer((_) async => []);

    // Act
    final result = await getAllDues();

    // Assert
    expect(result, isEmpty);
    verify(() => mockDueRepo.getDues()).called(1);
  });
}
