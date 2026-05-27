import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/data/repositories/settings_repository.dart';

class ResetAllData {
  final DueRepository dueRepository;
  final SettingsRepository settingsRepository;

  ResetAllData({required this.dueRepository, required this.settingsRepository});

  Future<void> call() async {
    await dueRepository.clearAllData();
    await settingsRepository.clearAllData();
  }
}
