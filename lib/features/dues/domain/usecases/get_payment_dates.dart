import 'package:myduesapp/features/dues/data/repositories/settings_repository.dart';

class GetPaymentDates {
  final SettingsRepository repository;

  GetPaymentDates({required this.repository});

  Future<List<String>> call() async {
    final settings = await repository.getBillingDates();
    if (settings == null) {
      return [];
    }

    final decoded = settings.getDecodedValue();
    if (decoded is! List) {
      return [];
    }

    final values = decoded.map((e) => e.toString()).toList();
    values.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return values;
  }
}
