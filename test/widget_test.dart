import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/application/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/presentation/pages/home.dart';
import 'package:myduesapp/injection_container.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await init();
  });

  setUp(() async {
    await sl<ResetAllData>().call();
  });

  testWidgets('home page renders loan split form', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyHomePage(title: 'MyDues', autoLoadPreview: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MyDues'), findsWidgets);
    expect(find.text('Create loan split'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    expect(find.byKey(const Key('titleField')), findsOneWidget);
    expect(find.byKey(const Key('amountField')), findsOneWidget);
    expect(find.byKey(const Key('installmentsField')), findsOneWidget);

    expect(find.text('Principal amount (PHP)'), findsOneWidget);

    await tester.tap(find.text('Monthly'));
    await tester.pump();

    expect(find.text('Monthly amount to pay (PHP)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('You currently have no dues'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('You currently have no dues'), findsOneWidget);
  });
}
