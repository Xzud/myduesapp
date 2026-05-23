// This is a basic Flutter widget test for the home page.
// 
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:myduesapp/main.dart';
import 'package:get_it/get_it.dart';
import 'package:myduesapp/injection_container.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/domain/usecases/create_due.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';
import 'package:myduesapp/core/database/database_helper.dart';

// Mock classes for dependency injection
class MockDueRepository extends Mock implements DueRepository {}
class MockGetPaymentDates extends Mock implements GetPaymentDates {}
class MockCreateDue extends Mock implements CreateDue {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

void main() {
  final GetIt getIt = GetIt.instance;

  setUp(() async {
    // Initialize FFI database factory for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Reset GetIt to ensure clean state for each test
    getIt.reset();
    
    // Register mock dependencies for testing
    final mockDueRepository = MockDueRepository();
    getIt.registerLazySingleton<DueRepository>(() => mockDueRepository);
    getIt.registerLazySingleton<GetPaymentDates>(() => MockGetPaymentDates());
    getIt.registerLazySingleton<CreateDue>(() => MockCreateDue());
    getIt.registerFactory(() => DueFormController(
      getPaymentDates: sl(),
      createDueUseCase: sl(),
    ));
    
    // Register the database helper
    final mockDatabaseHelper = MockDatabaseHelper();
    getIt.registerLazySingleton<DatabaseHelper>(() => mockDatabaseHelper);
  });

  tearDown(() {
    getIt.reset();
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('Home page displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the app bar title is correct.
    expect(find.text('MyDues'), findsOneWidget);
    
    // Verify that the "Add a new due" text is present.
    expect(find.text('Add a new due'), findsOneWidget);
    
    // Verify that text fields are present (3 visible by default, 4 when recurring is checked).
    expect(find.byType(TextField), findsNWidgets(3)); // Name, Amount, Date (interval hidden by default)
    
    // Verify that buttons are present.
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('Text fields accept input', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Enter text in the name field.
    await tester.enterText(find.byKey(const Key('nameField')), 'Test Due');
    expect(find.text('Test Due'), findsOneWidget);

    // Enter text in the amount field.
    await tester.enterText(find.byKey(const Key('amountField')), '100.50');
    expect(find.text('100.50'), findsOneWidget);

    // Enter text in the date field.
    await tester.enterText(find.byKey(const Key('dateField')), '15');
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('Recurring checkbox toggles correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Initially, recurring should be unchecked.
    expect(find.byType(Checkbox).first, findsOneWidget);
    expect(find.text('Recurring'), findsOneWidget);
    
    // Tap the checkbox to toggle it.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    
    // After tapping, the interval text field should appear.
    expect(find.byKey(const Key('intervalField')), findsOneWidget);
  });
}