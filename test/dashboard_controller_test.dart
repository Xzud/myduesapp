import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/get_dashboard_summary.dart';
import 'package:myduesapp/features/dues/domain/entities/dashboard_summary_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/dashboard_controller.dart';

class MockGetDashboardSummary extends Mock implements GetDashboardSummary {}

void main() {
  late MockGetDashboardSummary mockGetDashboardSummary;
  late DashboardController controller;

  setUp(() {
    mockGetDashboardSummary = MockGetDashboardSummary();
    controller = DashboardController(
      getDashboardSummary: mockGetDashboardSummary,
    );
  });

  test('starts with an empty dashboard summary', () {
    expect(controller.summary, const DashboardSummary.empty());
    expect(controller.isLoading, false);
    expect(controller.errorMessage, isNull);
  });

  test('loads dashboard summary successfully', () async {
    const summary = DashboardSummary(
      totalCount: 4,
      paidCount: 1,
      unpaidCount: 3,
      overdueCount: 2,
      dueTodayCount: 1,
      upcomingCount: 1,
      recurringCount: 2,
      oneTimeCount: 2,
      completeCount: 1,
      totalAmount: 1000,
      paidAmount: 250,
      unpaidAmount: 750,
      overdueAmount: 500,
      monthlySummaries: [],
    );

    when(
      () => mockGetDashboardSummary.call(
        referenceDate: any(named: 'referenceDate'),
      ),
    ).thenAnswer((_) async => summary);

    await controller.loadSummary(referenceDate: DateTime(2026, 5, 29));

    expect(controller.summary, summary);
    expect(controller.isLoading, false);
    expect(controller.errorMessage, isNull);
    verify(
      () => mockGetDashboardSummary.call(referenceDate: DateTime(2026, 5, 29)),
    ).called(1);
  });

  test('stores error when dashboard summary fails', () async {
    when(
      () => mockGetDashboardSummary.call(
        referenceDate: any(named: 'referenceDate'),
      ),
    ).thenThrow(Exception('Summary failed'));

    await controller.loadSummary(referenceDate: DateTime(2026, 5, 29));

    expect(controller.isLoading, false);
    expect(controller.errorMessage, 'Exception: Summary failed');
  });
}
