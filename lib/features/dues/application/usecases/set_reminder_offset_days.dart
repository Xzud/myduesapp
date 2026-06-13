import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class SetReminderOffsetDays {
  final SettingsRepository repository;

  SetReminderOffsetDays({required this.repository});

  Future<void> call(int days) async {
    await repository.setReminderOffsetDays(days);
  }
}
