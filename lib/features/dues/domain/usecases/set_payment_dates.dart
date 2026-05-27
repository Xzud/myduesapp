import 'package:myduesapp/features/dues/data/repositories/settings_repository.dart';

class SetPaymentDates {
  final SettingsRepository repository;

  SetPaymentDates({required this.repository});

  Future<void> call(List<int> values) async {
    await repository.setBillingDates(values);
  }
}
