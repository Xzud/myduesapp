import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/delete_due.dart';
import 'package:myduesapp/features/dues/application/usecases/end_recurring_series.dart';
import 'package:myduesapp/features/dues/application/usecases/filter_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/get_due_filter_state.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_paid.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_filter_state.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_due_reminders.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_recurring_templates.dart';
import 'package:myduesapp/features/dues/application/usecases/update_due.dart';
import 'package:myduesapp/features/dues/application/usecases/update_recurring_series.dart';
import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';

class MockGetAllDues extends Mock implements GetAllDues {}

class MockSetDuePaid extends Mock implements SetDuePaid {}

class MockUpdateDue extends Mock implements UpdateDue {}

class MockDeleteDue extends Mock implements DeleteDue {}

class MockGetDueFilterState extends Mock implements GetDueFilterState {}

class MockSetDueFilterState extends Mock implements SetDueFilterState {}

class MockUpdateRecurringSeries extends Mock implements UpdateRecurringSeries {}

class MockEndRecurringSeries extends Mock implements EndRecurringSeries {}

class MockSyncRecurringTemplates extends Mock
    implements SyncRecurringTemplates {}

class MockSyncDueReminders extends Mock implements SyncDueReminders {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const DueEntity(id: 0, name: '', amount: 0, dayOfMonth: 1),
    );
    registerFallbackValue(const DueFilterState());
  });

  late DueController controller;
  late MockGetAllDues mockGetAllDues;
  late MockSetDuePaid mockSetDuePaid;
  late MockUpdateDue mockUpdateDue;
  late MockDeleteDue mockDeleteDue;
  late MockGetDueFilterState mockGetDueFilterState;
  late MockSetDueFilterState mockSetDueFilterState;
  late MockUpdateRecurringSeries mockUpdateRecurringSeries;
  late MockEndRecurringSeries mockEndRecurringSeries;
  late MockSyncRecurringTemplates mockSyncRecurringTemplates;
  late MockSyncDueReminders mockSyncDueReminders;
  late FilterDues filterDues;

  setUp(() {
    mockGetAllDues = MockGetAllDues();
    mockSetDuePaid = MockSetDuePaid();
    mockUpdateDue = MockUpdateDue();
    mockDeleteDue = MockDeleteDue();
    mockGetDueFilterState = MockGetDueFilterState();
    mockSetDueFilterState = MockSetDueFilterState();
    mockUpdateRecurringSeries = MockUpdateRecurringSeries();
    mockEndRecurringSeries = MockEndRecurringSeries();
    mockSyncRecurringTemplates = MockSyncRecurringTemplates();
    mockSyncDueReminders = MockSyncDueReminders();
    filterDues = FilterDues();
    when(
      () => mockGetDueFilterState.call(),
    ).thenAnswer((_) async => const DueFilterState());
    when(() => mockSetDueFilterState.call(any())).thenAnswer((_) async {});
    when(
      () => mockSyncRecurringTemplates.call(),
    ).thenAnswer((_) async => false);
    when(() => mockSyncDueReminders.call()).thenAnswer((_) async {});
    controller = DueController(
      getAllDues: mockGetAllDues,
      getDueFilterState: mockGetDueFilterState,
      setDueFilterState: mockSetDueFilterState,
      filterDues: filterDues,
      setDuePaid: mockSetDuePaid,
      updateDue: mockUpdateDue,
      deleteDue: mockDeleteDue,
      updateRecurringSeries: mockUpdateRecurringSeries,
      endRecurringSeries: mockEndRecurringSeries,
      syncRecurringTemplates: mockSyncRecurringTemplates,
      syncDueReminders: mockSyncDueReminders,
    );
  });

  test('should fetch dues and expose loading state', () async {
    when(() => mockGetAllDues()).thenAnswer(
      (_) async => [
        MonthlyDue(
          month: 'May 2026',
          dues: [
            Due(id: 1, name: 'Loan A', price: 100, paid: false, dayOfMonth: 5),
          ],
        ),
      ],
    );

    final future = controller.fetchDues();
    expect(controller.isLoading, true);
    await future;

    expect(controller.isLoading, false);
    expect(controller.errorMessage, isNull);
    expect(controller.dues, hasLength(1));
    verify(() => mockGetAllDues()).called(1);
    verify(() => mockGetDueFilterState.call()).called(1);
    verify(() => mockSyncRecurringTemplates.call()).called(1);
  });

  test('should load saved filter state only once', () async {
    when(() => mockGetDueFilterState.call()).thenAnswer(
      (_) async => const DueFilterState(status: DueStatusFilter.unpaid),
    );
    when(() => mockGetAllDues()).thenAnswer((_) async => []);

    await controller.fetchDues();
    await controller.fetchDues();

    expect(controller.filterState.status, DueStatusFilter.unpaid);
    verify(() => mockGetDueFilterState.call()).called(1);
  });

  test('should filter dues by search query', () async {
    when(() => mockGetAllDues()).thenAnswer(
      (_) async => [
        MonthlyDue(
          month: 'May 2026',
          dues: [
            Due(
              id: 1,
              name: 'Internet',
              price: 100,
              paid: false,
              dayOfMonth: 5,
            ),
            Due(id: 2, name: 'Phone', price: 80, paid: false, dayOfMonth: 6),
          ],
        ),
      ],
    );

    await controller.fetchDues();
    controller.updateSearchQuery('phone');

    expect(controller.filteredDues, hasLength(1));
    expect(controller.filteredDues.single.dues.map((due) => due.name), [
      'Phone',
    ]);
  });

  test('should persist filter state updates', () async {
    when(() => mockGetAllDues()).thenAnswer((_) async => []);

    await controller.fetchDues();
    await controller.updateTypeFilter(DueTypeFilter.recurring);

    expect(controller.filterState.type, DueTypeFilter.recurring);
    verify(
      () => mockSetDueFilterState.call(
        const DueFilterState(type: DueTypeFilter.recurring),
      ),
    ).called(1);
  });

  test('should toggle paid without reloading dues', () async {
    when(() => mockGetAllDues()).thenAnswer((_) async {
      return [
        MonthlyDue(
          month: 'May 2026',
          dues: [
            Due(id: 1, name: 'Loan A', price: 100, paid: false, dayOfMonth: 5),
          ],
        ),
      ];
    });
    when(() => mockSetDuePaid.call(1, true)).thenAnswer((_) async {});

    await controller.fetchDues();
    await controller.togglePaid(dueId: 1, paid: true);

    expect(controller.errorMessage, isNull);
    expect(controller.dues.first.dues.first.paid, true);
    verify(() => mockSetDuePaid.call(1, true)).called(1);
    verify(() => mockSyncRecurringTemplates.call()).called(2);
    verify(() => mockSyncDueReminders.call()).called(1);
    verify(() => mockGetAllDues()).called(2);
  });

  test('should update due and refresh dues', () async {
    var calls = 0;
    when(() => mockGetAllDues()).thenAnswer((_) async {
      calls += 1;
      return [
        MonthlyDue(
          month: 'May 2026',
          dues: [
            Due(
              id: 1,
              name: calls > 1 ? 'Loan A Updated' : 'Loan A',
              price: calls > 1 ? 150 : 100,
              paid: false,
              dayOfMonth: 5,
            ),
          ],
        ),
      ];
    });
    when(() => mockUpdateDue.call(any())).thenAnswer((_) async {});

    await controller.fetchDues();
    await controller.updateDueItem(
      const DueEntity(
        id: 1,
        name: 'Loan A Updated',
        amount: 150,
        dayOfMonth: 5,
      ),
    );

    expect(controller.errorMessage, isNull);
    expect(controller.dues.first.dues.first.name, 'Loan A Updated');
    verify(() => mockUpdateDue.call(any())).called(1);
    verify(() => mockSyncRecurringTemplates.call()).called(2);
    verify(() => mockSyncDueReminders.call()).called(1);
  });

  test('should delete due and refresh dues', () async {
    var calls = 0;
    when(() => mockGetAllDues()).thenAnswer((_) async {
      calls += 1;
      return calls > 1
          ? []
          : [
              MonthlyDue(
                month: 'May 2026',
                dues: [
                  Due(
                    id: 1,
                    name: 'Loan A',
                    price: 100,
                    paid: false,
                    dayOfMonth: 5,
                  ),
                ],
              ),
            ];
    });
    when(() => mockDeleteDue.call(1)).thenAnswer((_) async {});

    await controller.fetchDues();
    await controller.deleteDueItem(1);

    expect(controller.errorMessage, isNull);
    expect(controller.dues, isEmpty);
    verify(() => mockDeleteDue.call(1)).called(1);
    verify(() => mockSyncRecurringTemplates.call()).called(2);
    verify(() => mockSyncDueReminders.call()).called(1);
  });

  test('should delete multiple dues and refresh once', () async {
    var calls = 0;
    when(() => mockGetAllDues()).thenAnswer((_) async {
      calls += 1;
      return calls > 1
          ? []
          : [
              MonthlyDue(
                month: 'May 2026',
                dues: [
                  Due(
                    id: 1,
                    name: 'Loan A',
                    price: 100,
                    paid: false,
                    dayOfMonth: 5,
                  ),
                  Due(
                    id: 2,
                    name: 'Loan A',
                    price: 100,
                    paid: false,
                    dayOfMonth: 5,
                  ),
                ],
              ),
            ];
    });
    when(() => mockDeleteDue.call(any())).thenAnswer((_) async {});

    await controller.fetchDues();
    await controller.deleteDueItems([2, 1, 2]);

    expect(controller.errorMessage, isNull);
    expect(controller.dues, isEmpty);
    verify(() => mockDeleteDue.call(1)).called(1);
    verify(() => mockDeleteDue.call(2)).called(1);
    verify(() => mockSyncRecurringTemplates.call()).called(2);
    verify(() => mockSyncDueReminders.call()).called(1);
  });

  test('should mark multiple dues paid and refresh once', () async {
    var calls = 0;
    when(() => mockGetAllDues()).thenAnswer((_) async {
      calls += 1;
      return [
        MonthlyDue(
          month: 'May 2026',
          dues: [
            Due(
              id: 1,
              name: 'Loan A',
              price: 100,
              paid: calls > 1,
              dayOfMonth: 5,
            ),
            Due(
              id: 2,
              name: 'Loan A',
              price: 100,
              paid: calls > 1,
              dayOfMonth: 5,
            ),
          ],
        ),
      ];
    });
    when(() => mockSetDuePaid.call(any(), true)).thenAnswer((_) async {});

    await controller.fetchDues();
    await controller.setDueItemsPaid([2, 1, 2], true);

    expect(controller.errorMessage, isNull);
    expect(controller.dues.first.dues.every((due) => due.paid), true);
    verify(() => mockSetDuePaid.call(1, true)).called(1);
    verify(() => mockSetDuePaid.call(2, true)).called(1);
    verify(() => mockSyncRecurringTemplates.call()).called(2);
    verify(() => mockSyncDueReminders.call()).called(1);
    verify(() => mockGetAllDues()).called(2);
  });
}
