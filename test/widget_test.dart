import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/create_recurring_due.dart';
import 'package:myduesapp/features/dues/application/usecases/create_split_due.dart';
import 'package:myduesapp/features/dues/application/usecases/delete_due.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart'
    show Due, GetAllDues, MonthlyDue;
import 'package:myduesapp/features/dues/application/usecases/get_dashboard_summary.dart';
import 'package:myduesapp/features/dues/application/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/application/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_paid.dart';
import 'package:myduesapp/features/dues/application/usecases/update_due.dart';
import 'package:myduesapp/features/dues/domain/entities/dashboard_summary_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/dashboard_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';
import 'package:myduesapp/features/dues/presentation/pages/create.dart';
import 'package:myduesapp/features/dues/presentation/pages/dues.dart'
    show DuesPage;
import 'package:myduesapp/features/dues/presentation/pages/home.dart';
import 'package:myduesapp/injection_container.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockGetPaymentDates extends Mock implements GetPaymentDates {}

class _MockCreateSplitDue extends Mock implements CreateSplitDue {}

class _MockCreateRecurringDue extends Mock implements CreateRecurringDue {}

class _MockGetAllDues extends Mock implements GetAllDues {}

class _MockSetDuePaid extends Mock implements SetDuePaid {}

class _MockUpdateDue extends Mock implements UpdateDue {}

class _MockDeleteDue extends Mock implements DeleteDue {}

class _FakeDueFormController extends DueFormController {
  _FakeDueFormController()
    : super(
        getPaymentDates: _MockGetPaymentDates(),
        createSplitDue: _MockCreateSplitDue(),
        createRecurringDue: _MockCreateRecurringDue(),
      );

  @override
  Future<List<int>> loadBillingDays() async => [5, 15];
}

class _FakeDueController extends DueController {
  _FakeDueController(this._dues)
    : super(
        getAllDues: _MockGetAllDues(),
        setDuePaid: _MockSetDuePaid(),
        updateDue: _MockUpdateDue(),
        deleteDue: _MockDeleteDue(),
      );

  final List<MonthlyDue> _dues;
  final List<int> toggleCalls = [];
  final List<List<int>> bulkPaidCalls = [];
  final List<bool> bulkPaidValues = [];

  @override
  List<MonthlyDue> get dues => _dues;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> fetchDues() async {}

  @override
  Future<void> togglePaid({required int dueId, required bool paid}) async {
    toggleCalls.add(dueId);
    for (final month in _dues) {
      for (final due in month.dues) {
        if (due.id == dueId) {
          due.paid = paid;
        }
      }
    }
    notifyListeners();
  }

  @override
  Future<void> setDueItemsPaid(List<int> dueIds, bool paid) async {
    bulkPaidCalls.add([...dueIds]);
    bulkPaidValues.add(paid);
    final ids = dueIds.toSet();
    for (final month in _dues) {
      for (final due in month.dues) {
        if (ids.contains(due.id)) {
          due.paid = paid;
        }
      }
    }
    notifyListeners();
  }
}

class _FakeDashboardController extends DashboardController {
  _FakeDashboardController(this._summary)
    : super(getDashboardSummary: _MockGetDashboardSummary());

  final DashboardSummary _summary;

  @override
  DashboardSummary get summary => _summary;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<void> loadSummary({DateTime? referenceDate}) async {}
}

class _MockGetDashboardSummary extends Mock implements GetDashboardSummary {}

DashboardSummary _dashboardSummary() {
  return DashboardSummary(
    totalCount: 10,
    paidCount: 3,
    unpaidCount: 7,
    overdueCount: 2,
    dueTodayCount: 1,
    upcomingCount: 4,
    recurringCount: 6,
    oneTimeCount: 4,
    completeCount: 2,
    totalAmount: 25000,
    paidAmount: 7000,
    unpaidAmount: 18000,
    overdueAmount: 4000,
    monthlySummaries: const [
      DashboardMonthlySummary(
        month: 'May 2026',
        totalCount: 6,
        paidCount: 2,
        unpaidCount: 4,
        overdueCount: 1,
        totalAmount: 15000,
        paidAmount: 5000,
        unpaidAmount: 10000,
      ),
      DashboardMonthlySummary(
        month: 'June 2026',
        totalCount: 4,
        paidCount: 1,
        unpaidCount: 3,
        overdueCount: 1,
        totalAmount: 10000,
        paidAmount: 2000,
        unpaidAmount: 8000,
      ),
    ],
  );
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await init();
  });

  setUp(() async {
    await sl<ResetAllData>().call();

    if (sl.isRegistered<DueFormController>()) {
      sl.unregister<DueFormController>();
    }
    if (sl.isRegistered<DashboardController>()) {
      sl.unregister<DashboardController>();
    }
    if (sl.isRegistered<DueController>()) {
      sl.unregister<DueController>();
    }

    sl.registerSingleton<DueFormController>(_FakeDueFormController());
    sl.registerSingleton<DashboardController>(
      _FakeDashboardController(_dashboardSummary()),
    );
    sl.registerSingleton<DueController>(
      _FakeDueController([
        MonthlyDue(
          month: 'May 2026',
          dues: [
            Due(
              id: 1,
              name: 'Laptop',
              price: 12000,
              paid: false,
              dayOfMonth: 5,
              dueDate: '2026-05-05',
            ),
            Due(
              id: 2,
              name: 'Phone',
              price: 8000,
              paid: true,
              dayOfMonth: 15,
              dueDate: '2026-05-15',
            ),
          ],
        ),
      ]),
    );
  });

  testWidgets('home page renders dashboard analytics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(title: 'MyDues', autoLoadPreview: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('MyDues'), findsWidgets);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Create due'), findsWidgets);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Counts'), findsOneWidget);
    expect(find.text('Paid'), findsWidgets);
    expect(find.text('Unpaid'), findsWidgets);
    expect(find.text('Overdue'), findsWidgets);
    expect(find.text('Due today'), findsWidgets);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Recurring'), findsWidgets);
    expect(find.text('One-time'), findsWidgets);
    expect(find.text('Complete'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Amounts'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Amounts'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Monthly breakdown'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Monthly breakdown'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);
    expect(find.text('June 2026'), findsOneWidget);
    expect(
      find.text('Total 6 • Paid 2 • Unpaid 4 • Overdue 1'),
      findsOneWidget,
    );
    expect(
      find.text('Total 4 • Paid 1 • Unpaid 3 • Overdue 1'),
      findsOneWidget,
    );
  });

  testWidgets('create page renders loan split form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreatePage(title: 'Create', autoLoadPreview: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Create'), findsWidgets);
    expect(find.text('Create loan split'), findsOneWidget);
    expect(find.text('Loan split'), findsOneWidget);
    expect(find.text('Recurring bill'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    expect(find.byKey(const Key('titleField')), findsOneWidget);
    expect(find.byKey(const Key('amountField')), findsOneWidget);
    expect(find.byKey(const Key('installmentsField')), findsOneWidget);
    expect(find.byKey(const Key('interestField')), findsNothing);

    expect(find.text('Principal amount (PHP)'), findsOneWidget);
    expect(find.text('Include Interest'), findsOneWidget);
    expect(find.text('Billing period selection'), findsOneWidget);
    expect(find.text('Selected periods: 5, 15'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Monthly').last,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly amount to pay (PHP)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Include Interest'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Include Interest'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('interestField')), findsOneWidget);
    expect(find.text('Percentage'), findsOneWidget);
    expect(find.text('Monthly fixed'), findsOneWidget);
    expect(find.text('Total interest'), findsOneWidget);
    expect(find.text('Interest percentage (%)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Monthly fixed').last,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Monthly fixed').last);
    await tester.pumpAndSettle();

    expect(find.text('Monthly interest amount (PHP)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Total interest').last,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Total interest').last);
    await tester.pumpAndSettle();

    expect(find.text('Total interest amount (PHP)'), findsOneWidget);
  });

  testWidgets('create page renders recurring bill form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreatePage(title: 'Create', autoLoadPreview: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Recurring bill'));
    await tester.pumpAndSettle();

    expect(find.text('Create recurring bill'), findsOneWidget);
    expect(find.text('Amount (PHP)'), findsOneWidget);
    expect(find.byKey(const Key('recurringIntervalField')), findsOneWidget);
    expect(find.byKey(const Key('occurrencesField')), findsOneWidget);
    expect(find.text('Recurring billing day'), findsOneWidget);
    expect(find.text('Selected billing day: 5'), findsOneWidget);
    expect(find.text('Include Interest'), findsNothing);
    expect(find.byKey(const Key('installmentsField')), findsNothing);
  });

  testWidgets('overview row toggles paid when the card is tapped', (
    WidgetTester tester,
  ) async {
    final controller = _FakeDueController([
      MonthlyDue(
        month: 'May 2026',
        dues: [
          Due(
            id: 1,
            name: 'Laptop',
            price: 12000,
            paid: false,
            dayOfMonth: 5,
            dueDate: '2026-05-05',
          ),
          Due(
            id: 2,
            name: 'Phone',
            price: 8000,
            paid: true,
            dayOfMonth: 15,
            dueDate: '2026-05-15',
          ),
        ],
      ),
    ]);

    if (sl.isRegistered<DueController>()) {
      sl.unregister<DueController>();
    }
    sl.registerSingleton<DueController>(controller);

    await tester.pumpWidget(const MaterialApp(home: DuesPage()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Billing day 5'), findsOneWidget);
    expect(find.text('Billing day 15'), findsOneWidget);

    await tester.tap(find.text('Laptop'));
    await tester.pumpAndSettle();

    expect(controller.toggleCalls, [1]);
    expect(controller.dues.first.dues.first.paid, true);
  });

  testWidgets('overview opens loan details and marks all installments paid', (
    WidgetTester tester,
  ) async {
    final controller = _FakeDueController([
      MonthlyDue(
        month: 'May 2026',
        dues: [
          Due(
            id: 1,
            loanId: 'loan-1',
            name: 'Laptop',
            price: 6000,
            paid: false,
            installmentIndex: 1,
            installmentCount: 2,
            dayOfMonth: 5,
            dueDate: '2026-05-05',
          ),
          Due(
            id: 2,
            loanId: 'loan-1',
            name: 'Laptop',
            price: 6000,
            paid: false,
            installmentIndex: 2,
            installmentCount: 2,
            dayOfMonth: 15,
            dueDate: '2026-05-15',
          ),
        ],
      ),
    ]);

    if (sl.isRegistered<DueController>()) {
      sl.unregister<DueController>();
    }
    sl.registerSingleton<DueController>(controller);

    await tester.pumpWidget(const MaterialApp(home: DuesPage()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Laptop • Installment 1/2'), findsOneWidget);
    expect(find.text('Laptop • Installment 2/2'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();

    expect(find.text('Loan details'), findsOneWidget);
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Php 12000.00'), findsWidgets);
    expect(find.text('0/2'), findsOneWidget);

    await tester.tap(find.text('Mark all paid'));
    await tester.pumpAndSettle();

    expect(controller.bulkPaidCalls, [
      [1, 2],
    ]);
    expect(controller.bulkPaidValues, [true]);
    expect(controller.dues.first.dues.every((due) => due.paid), true);
    expect(find.text('2/2'), findsOneWidget);
  });
}
