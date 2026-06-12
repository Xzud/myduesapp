import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/get_default_billing_period_mode.dart';
import 'package:myduesapp/features/dues/application/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/application/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/application/usecases/set_default_billing_period_mode.dart';
import 'package:myduesapp/features/dues/application/usecases/set_payment_dates.dart';
import 'package:myduesapp/features/dues/domain/entities/billing_period_mode.dart';
import 'package:myduesapp/features/dues/presentation/controllers/settings_controller.dart';

class MockGetPaymentDates extends Mock implements GetPaymentDates {}

class MockSetPaymentDates extends Mock implements SetPaymentDates {}

class MockGetDefaultBillingPeriodMode extends Mock
    implements GetDefaultBillingPeriodMode {}

class MockSetDefaultBillingPeriodMode extends Mock
    implements SetDefaultBillingPeriodMode {}

class MockResetAllData extends Mock implements ResetAllData {}

void main() {
  setUpAll(() {
    registerFallbackValue(BillingPeriodMode.single);
  });

  late SettingsController controller;
  late MockGetPaymentDates mockGetPaymentDates;
  late MockSetPaymentDates mockSetPaymentDates;
  late MockGetDefaultBillingPeriodMode mockGetDefaultBillingPeriodMode;
  late MockSetDefaultBillingPeriodMode mockSetDefaultBillingPeriodMode;
  late MockResetAllData mockResetAllData;

  setUp(() {
    mockGetPaymentDates = MockGetPaymentDates();
    mockSetPaymentDates = MockSetPaymentDates();
    mockGetDefaultBillingPeriodMode = MockGetDefaultBillingPeriodMode();
    mockSetDefaultBillingPeriodMode = MockSetDefaultBillingPeriodMode();
    mockResetAllData = MockResetAllData();
    controller = SettingsController(
      getPaymentDates: mockGetPaymentDates,
      setPaymentDates: mockSetPaymentDates,
      getDefaultBillingPeriodMode: mockGetDefaultBillingPeriodMode,
      setDefaultBillingPeriodMode: mockSetDefaultBillingPeriodMode,
      resetAllData: mockResetAllData,
    );
  });

  test('reset should clear local billing days after success', () async {
    when(() => mockResetAllData.call()).thenAnswer((_) async {});
    when(() => mockGetPaymentDates.call()).thenAnswer((_) async => ['5', '15']);
    when(
      () => mockGetDefaultBillingPeriodMode.call(),
    ).thenAnswer((_) async => BillingPeriodMode.multiple);

    await controller.fetchPaymentDates();
    expect(controller.billingDays, [5, 15]);
    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.multiple);

    await controller.resetData();

    expect(controller.billingDays, isEmpty);
    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.single);
    verify(() => mockResetAllData.call()).called(1);
  });

  test('should load billing days and default billing period mode', () async {
    when(() => mockGetPaymentDates.call()).thenAnswer((_) async => ['15', '5']);
    when(
      () => mockGetDefaultBillingPeriodMode.call(),
    ).thenAnswer((_) async => BillingPeriodMode.single);

    await controller.fetchPaymentDates();

    expect(controller.billingDays, [5, 15]);
    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.single);
    verify(() => mockGetPaymentDates.call()).called(1);
    verify(() => mockGetDefaultBillingPeriodMode.call()).called(1);
  });

  test('should persist default billing period mode', () async {
    when(
      () => mockSetDefaultBillingPeriodMode.call(BillingPeriodMode.multiple),
    ).thenAnswer((_) async {});

    await controller.updateDefaultBillingPeriodMode(BillingPeriodMode.multiple);

    expect(controller.defaultBillingPeriodMode, BillingPeriodMode.multiple);
    expect(controller.errorMessage, isNull);
    verify(
      () => mockSetDefaultBillingPeriodMode.call(BillingPeriodMode.multiple),
    ).called(1);
  });
}
