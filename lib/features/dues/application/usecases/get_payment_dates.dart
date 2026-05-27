import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class GetPaymentDates {
  final SettingsRepository repository;

  GetPaymentDates({required this.repository});

  Future<List<String>> call() async {
    final values = await repository.getBillingDates();
    final sortedValues = values.toList()..sort();
    return sortedValues.map((value) => value.toString()).toList();
  }
}
