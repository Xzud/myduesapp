import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/infrastructure/datasources/settings_datasource.dart';
import 'package:myduesapp/features/dues/infrastructure/models/settings_model.dart';
import 'package:myduesapp/features/dues/infrastructure/repositories/settings_repository_impl.dart';

class MockSettingsDatasource extends Mock implements SettingsDatasource {}

void main() {
  late MockSettingsDatasource datasource;
  late SettingsRepositoryImpl repository;

  setUp(() {
    datasource = MockSettingsDatasource();
    repository = SettingsRepositoryImpl(datasource: datasource);
  });

  test('should default billing period mode to single when unset', () async {
    when(
      () => datasource.getSettings('default_billing_period_mode'),
    ).thenAnswer((_) async => null);

    final result = await repository.getDefaultBillingPeriodMode();

    expect(result, BillingPeriodMode.single);
  });

  test('should read stored default billing period mode', () async {
    when(
      () => datasource.getSettings('default_billing_period_mode'),
    ).thenAnswer(
      (_) async => SettingsModel.create(
        key: 'default_billing_period_mode',
        value: 'multiple',
      ),
    );

    final result = await repository.getDefaultBillingPeriodMode();

    expect(result, BillingPeriodMode.multiple);
  });

  test('should persist default billing period mode', () async {
    when(
      () => datasource.setSettings('default_billing_period_mode', 'multiple'),
    ).thenAnswer((_) async {});

    await repository.setDefaultBillingPeriodMode(BillingPeriodMode.multiple);

    verify(
      () => datasource.setSettings('default_billing_period_mode', 'multiple'),
    ).called(1);
  });
}
