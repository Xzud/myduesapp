import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/domain/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/domain/usecases/set_payment_dates.dart';
import 'package:myduesapp/features/dues/presentation/controllers/settings_controller.dart';

class MockGetPaymentDates extends Mock implements GetPaymentDates {}

class MockSetPaymentDates extends Mock implements SetPaymentDates {}

class MockResetAllData extends Mock implements ResetAllData {}

void main() {
  late SettingsController controller;
  late MockGetPaymentDates mockGetPaymentDates;
  late MockSetPaymentDates mockSetPaymentDates;
  late MockResetAllData mockResetAllData;

  setUp(() {
    mockGetPaymentDates = MockGetPaymentDates();
    mockSetPaymentDates = MockSetPaymentDates();
    mockResetAllData = MockResetAllData();
    controller = SettingsController(
      getPaymentDates: mockGetPaymentDates,
      setPaymentDates: mockSetPaymentDates,
      resetAllData: mockResetAllData,
    );
  });

  test('reset should clear local billing days after success', () async {
    when(() => mockResetAllData.call()).thenAnswer((_) async {});
    when(() => mockGetPaymentDates.call()).thenAnswer((_) async => ['5', '15']);

    await controller.fetchPaymentDates();
    expect(controller.billingDays, [5, 15]);

    await controller.resetData();

    expect(controller.billingDays, isEmpty);
    verify(() => mockResetAllData.call()).called(1);
  });
}
