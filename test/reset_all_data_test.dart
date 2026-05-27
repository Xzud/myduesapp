import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/data/repositories/settings_repository.dart';
import 'package:myduesapp/features/dues/domain/usecases/reset_all_data.dart';

class MockDueRepository extends Mock implements DueRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late ResetAllData usecase;
  late MockDueRepository mockDueRepository;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockDueRepository = MockDueRepository();
    mockSettingsRepository = MockSettingsRepository();
    usecase = ResetAllData(
      dueRepository: mockDueRepository,
      settingsRepository: mockSettingsRepository,
    );
  });

  test('should clear dues and settings', () async {
    when(() => mockDueRepository.clearAllData()).thenAnswer((_) async {});
    when(() => mockSettingsRepository.clearAllData()).thenAnswer((_) async {});

    await usecase.call();

    verify(() => mockDueRepository.clearAllData()).called(1);
    verify(() => mockSettingsRepository.clearAllData()).called(1);
  });
}
