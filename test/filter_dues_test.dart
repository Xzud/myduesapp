import 'package:flutter_test/flutter_test.dart';
import 'package:myduesapp/features/dues/application/usecases/filter_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';

void main() {
  late FilterDues usecase;
  late List<MonthlyDue> months;

  setUp(() {
    usecase = FilterDues();
    months = [
      MonthlyDue(
        month: 'June 2026',
        dues: [
          Due(
            id: 1,
            name: 'Internet',
            price: 1800,
            paid: false,
            dayOfMonth: 15,
            recurring: true,
            recurringInterval: 1,
            dueDate: '2026-06-15',
          ),
          Due(
            id: 2,
            name: 'Phone',
            price: 800,
            paid: true,
            dayOfMonth: 14,
            dueDate: '2026-06-14',
          ),
          Due(
            id: 3,
            name: 'Laptop',
            price: 2000,
            paid: false,
            dayOfMonth: 10,
            installmentIndex: 1,
            installmentCount: 3,
            loanId: 'loan_1',
            dueDate: '2026-06-10',
          ),
        ],
      ),
      MonthlyDue(
        month: 'July 2026',
        dues: [
          Due(
            id: 4,
            name: 'Gym',
            price: 600,
            paid: false,
            dayOfMonth: 2,
            dueDate: '2026-07-02',
          ),
        ],
      ),
    ];
  });

  test('should search dues by partial name', () {
    final result = usecase.call(
      months: months,
      filterState: const DueFilterState(),
      searchQuery: 'net',
      referenceDate: DateTime(2026, 6, 15),
    );

    expect(result, hasLength(1));
    expect(result.single.dues.map((due) => due.name), ['Internet']);
  });

  test('should filter overdue and exclude paid dues from status filters', () {
    final result = usecase.call(
      months: months,
      filterState: const DueFilterState(status: DueStatusFilter.overdue),
      referenceDate: DateTime(2026, 6, 15),
    );

    expect(result, hasLength(1));
    expect(result.single.dues.map((due) => due.name), ['Laptop']);
  });

  test('should filter recurring dues by quick view', () {
    final result = usecase.call(
      months: months,
      filterState: const DueFilterState(quickView: DueQuickView.recurring),
      referenceDate: DateTime(2026, 6, 15),
    );

    expect(result, hasLength(1));
    expect(result.single.dues.map((due) => due.name), ['Internet']);
  });

  test('should filter by type and month together', () {
    final result = usecase.call(
      months: months,
      filterState: const DueFilterState(
        type: DueTypeFilter.single,
        month: 'July 2026',
      ),
      referenceDate: DateTime(2026, 6, 15),
    );

    expect(result, hasLength(1));
    expect(result.single.month, 'July 2026');
    expect(result.single.dues.map((due) => due.name), ['Gym']);
  });
}
