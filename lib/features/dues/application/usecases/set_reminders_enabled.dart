import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class SetRemindersEnabled {
  final SettingsRepository repository;

  SetRemindersEnabled({required this.repository});

  Future<void> call(bool enabled) async {
    await repository.setRemindersEnabled(enabled);
  }
}
