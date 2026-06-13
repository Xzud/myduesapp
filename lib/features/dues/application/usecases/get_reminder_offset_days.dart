import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class GetReminderOffsetDays {
  final SettingsRepository repository;

  GetReminderOffsetDays({required this.repository});

  Future<int> call() async {
    return await repository.getReminderOffsetDays();
  }
}
