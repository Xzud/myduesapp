import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/delete_due.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  late DeleteDue usecase;
  late MockDueRepository mockDueRepository;

  setUp(() {
    mockDueRepository = MockDueRepository();
    usecase = DeleteDue(repository: mockDueRepository);
  });

  test('should delete a due when called', () async {
    when(() => mockDueRepository.deleteDue(any())).thenAnswer((_) async {});

    await usecase(7);

    verify(() => mockDueRepository.deleteDue(7)).called(1);
  });

  test('should surface repository errors', () async {
    when(
      () => mockDueRepository.deleteDue(any()),
    ).thenThrow(Exception('Database error'));

    expect(() async => usecase(7), throwsException);
  });
}
