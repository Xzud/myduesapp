import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class GetRemindersEnabled {
  final SettingsRepository repository;

  GetRemindersEnabled({required this.repository});

  Future<bool> call() async {
    return await repository.getRemindersEnabled();
  }
}
