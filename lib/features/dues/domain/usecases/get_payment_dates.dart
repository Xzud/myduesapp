import 'package:myduesapp/features/dues/data/repositories/settings_repository.dart';

class GetPaymentDates {
  final SettingsRepository repository;

  GetPaymentDates({required this.repository});

  Future<List<String>> call() async {
    return [];
  }
}
