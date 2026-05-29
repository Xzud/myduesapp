import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/create_split_due.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/application/usecases/delete_due.dart';
import 'package:myduesapp/features/dues/application/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_paid.dart';
import 'package:myduesapp/features/dues/application/usecases/update_due.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';
import 'package:myduesapp/features/dues/presentation/pages/home.dart';
import 'package:myduesapp/injection_container.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockGetPaymentDates extends Mock implements GetPaymentDates {}

class _MockCreateSplitDue extends Mock implements CreateSplitDue {}

class _MockGetAllDues extends Mock implements GetAllDues {}

class _MockSetDuePaid extends Mock implements SetDuePaid {}

class _MockUpdateDue extends Mock implements UpdateDue {}

class _MockDeleteDue extends Mock implements DeleteDue {}

class _FakeDueFormController extends DueFormController {
  _FakeDueFormController()
    : super(
        getPaymentDates: _MockGetPaymentDates(),
        createSplitDue: _MockCreateSplitDue(),
      );

  @override
  Future<List<int>> loadBillingDays() async => [5, 15];
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
    if (sl.isRegistered<DueController>()) {
      sl.unregister<DueController>();
    }

    sl.registerSingleton<DueFormController>(_FakeDueFormController());
    sl.registerSingleton<DueController>(
      DueController(
        getAllDues: _MockGetAllDues(),
        setDuePaid: _MockSetDuePaid(),
        updateDue: _MockUpdateDue(),
        deleteDue: _MockDeleteDue(),
      ),
    );
  });

  testWidgets('home page renders loan split form', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyHomePage(title: 'MyDues', autoLoadPreview: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('MyDues'), findsWidgets);
    expect(find.text('Create loan split'), findsOneWidget);
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
}
