import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/presentation/pages/home.dart';
import 'package:myduesapp/injection_container.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await init();
  });

  testWidgets('home page renders loan split form', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MyHomePage(title: 'MyDues', autoLoadPreview: false)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MyDues'), findsWidgets);
    expect(find.text('Create loan split'), findsOneWidget);

    expect(find.byKey(const Key('titleField')), findsOneWidget);
    expect(find.byKey(const Key('principalField')), findsOneWidget);
    expect(find.byKey(const Key('installmentsField')), findsOneWidget);

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('You currently have no dues'), findsOneWidget);
  });
}
