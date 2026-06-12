import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class SetDefaultBillingPeriodMode {
  final SettingsRepository repository;

  SetDefaultBillingPeriodMode({required this.repository});

  Future<void> call(BillingPeriodMode mode) {
    return repository.setDefaultBillingPeriodMode(mode);
  }
}
