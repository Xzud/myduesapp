import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/update_due.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const DueEntity(id: 0, name: '', amount: 0, dayOfMonth: 1),
    );
  });

  late UpdateDue usecase;
  late MockDueRepository mockDueRepository;

  setUp(() {
    mockDueRepository = MockDueRepository();
    usecase = UpdateDue(repository: mockDueRepository);
  });

  test('should update a due when called', () async {
    final due = DueEntity(
      id: 1,
      name: 'Updated Due',
      amount: 150.0,
      paid: true,
      dayOfMonth: 15,
      recurring: false,
      recurringInterval: 1,
      createdAt: '2023-09-15 10:00:00',
      updatedAt: '2023-09-15 10:00:00',
    );

    when(() => mockDueRepository.updateDue(any())).thenAnswer((_) async {});

    await usecase(due);

    verify(() => mockDueRepository.updateDue(due)).called(1);
  });

  test('should surface repository errors', () async {
    final due = DueEntity(
      id: 1,
      name: 'Updated Due',
      amount: 150.0,
      paid: true,
      dayOfMonth: 15,
      recurring: false,
      recurringInterval: 1,
      createdAt: '2023-09-15 10:00:00',
      updatedAt: '2023-09-15 10:00:00',
    );

    when(
      () => mockDueRepository.updateDue(any()),
    ).thenThrow(Exception('Database error'));

    expect(() async => usecase(due), throwsException);
  });
}
