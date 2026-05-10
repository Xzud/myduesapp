import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/data/models/due_model.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_all_dues.dart';

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
      // Add mock due data here
      DueModel(
        name: 'Electricity Bill',
        amount: 50.0,
        paid: false,
        dayOfMonth: 15,
        recurring: false,
        recurringInterval: 0,
      ),
    ];
    when(() => mockDueRepo.getDues()).thenAnswer((_) async => mockDues);

    final expectedDues = [
      MonthlyDue(
        month: mockDues[0]
            .getMonthYear(), // Assuming the mock due is for September 2023
        dues: [
          Due(
            name: mockDues[0].name,
            price: mockDues[0].amount,
            paid: mockDues[0].paid,
          ),
        ],
      ),
    ];

    // Act
    final result = await getAllDues();

    // Assert
    expect(result[0].month, expectedDues[0].month);
    expect(result[0].dues[0].name, expectedDues[0].dues[0].name);
    expect(result[0].dues[0].price, expectedDues[0].dues[0].price);
    expect(result[0].dues[0].paid, expectedDues[0].dues[0].paid);
    verify(() => mockDueRepo.getDues()).called(1);
  });
}
