import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/data/models/due_model.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/domain/usecases/create_due.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  late CreateDue createDue;
  late MockDueRepository mockDueRepository;

  setUpAll(() {
    registerFallbackValue(
      DueModel(
        id: 0,
        name: '',
        amount: 0.0,
        paid: false,
        dayOfMonth: 0,
        recurring: false,
        recurringInterval: 1,
        createdAt: '',
        updatedAt: '',
      ),
    );
  });

  setUp(() {
    mockDueRepository = MockDueRepository();
    createDue = CreateDue(repository: mockDueRepository);
  });

  test('should create a due when called', () async {
    // Arrange
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

    when(
      () => mockDueRepository.createDue(any()),
    ).thenAnswer((_) async => Future.value());

    // Act
    await createDue(due);

    // Assert
    verify(() => mockDueRepository.createDue(due)).called(1);
  });

  test('should handle errors when creating a due', () async {
    // Arrange
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

    when(
      () => mockDueRepository.createDue(any()),
    ).thenThrow(Exception('Database error'));

    // Act & Assert
    expect(() async => await createDue(due), throwsException);
    verify(() => mockDueRepository.createDue(due)).called(1);
  });
}
