import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class GetDefaultBillingPeriodMode {
  final SettingsRepository repository;

  GetDefaultBillingPeriodMode({required this.repository});

  Future<BillingPeriodMode> call() {
    return repository.getDefaultBillingPeriodMode();
  }
}
