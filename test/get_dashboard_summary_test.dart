import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:myduesapp/features/dues/application/usecases/get_dashboard_summary.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';
import 'package:myduesapp/features/dues/domain/repositories/due_repository.dart';

class MockDueRepository extends Mock implements DueRepository {}

void main() {
  late MockDueRepository mockRepository;
  late GetDashboardSummary getDashboardSummary;

  setUp(() {
    mockRepository = MockDueRepository();
    getDashboardSummary = GetDashboardSummary(repository: mockRepository);
  });

  test('should build dashboard analytics from dues', () async {
    when(() => mockRepository.getDues()).thenAnswer(
      (_) async => [
        const DueEntity(
          id: 1,
          name: 'Electricity',
          amount: 50,
          paid: false,
          complete: false,
          recurring: false,
          dayOfMonth: 15,
          dueDate: '2023-09-15T10:00:00',
          createdAt: '2023-09-10T10:00:00',
        ),
        const DueEntity(
          id: 2,
          name: 'Internet',
          amount: 60,
          paid: true,
          complete: false,
          recurring: true,
          dayOfMonth: 20,
          dueDate: '2023-09-20T10:00:00',
          createdAt: '2023-09-12T10:00:00',
        ),
        const DueEntity(
          id: 3,
          name: 'Rent',
          amount: 100,
          paid: false,
          complete: false,
          recurring: false,
          dayOfMonth: 1,
          dueDate: '2023-10-01T10:00:00',
          createdAt: '2023-10-01T08:00:00',
        ),
        const DueEntity(
          id: 4,
          name: 'Groceries',
          amount: 75,
          paid: false,
          complete: true,
          recurring: false,
          dayOfMonth: 5,
          createdAt: '2023-10-05T08:00:00',
        ),
      ],
    );

    final result = await getDashboardSummary(
      referenceDate: DateTime(2023, 10, 15),
    );

    expect(result.totalCount, 4);
    expect(result.paidCount, 1);
    expect(result.unpaidCount, 2);
    expect(result.overdueCount, 2);
    expect(result.dueTodayCount, 0);
    expect(result.upcomingCount, 0);
    expect(result.recurringCount, 1);
    expect(result.oneTimeCount, 3);
    expect(result.completeCount, 1);
    expect(result.totalAmount, 285);
    expect(result.paidAmount, 60);
    expect(result.unpaidAmount, 150);
    expect(result.overdueAmount, 150);

    expect(result.monthlySummaries, hasLength(2));

    final september = result.monthlySummaries.firstWhere(
      (summary) => summary.month == 'September 2023',
    );
    expect(september.totalCount, 2);
    expect(september.paidCount, 1);
    expect(september.unpaidCount, 1);
    expect(september.overdueCount, 1);
    expect(september.totalAmount, 110);
    expect(september.paidAmount, 60);
    expect(september.unpaidAmount, 50);

    final october = result.monthlySummaries.firstWhere(
      (summary) => summary.month == 'October 2023',
    );
    expect(october.totalCount, 2);
    expect(october.paidCount, 0);
    expect(october.unpaidCount, 1);
    expect(october.overdueCount, 1);
    expect(october.totalAmount, 175);
    expect(october.paidAmount, 0);
    expect(october.unpaidAmount, 100);

    verify(() => mockRepository.getDues()).called(1);
  });

  test('should return empty dashboard summary when no dues exist', () async {
    when(() => mockRepository.getDues()).thenAnswer((_) async => []);

    final result = await getDashboardSummary(
      referenceDate: DateTime(2023, 10, 15),
    );

    expect(result.totalCount, 0);
    expect(result.paidCount, 0);
    expect(result.unpaidCount, 0);
    expect(result.overdueCount, 0);
    expect(result.dueTodayCount, 0);
    expect(result.upcomingCount, 0);
    expect(result.recurringCount, 0);
    expect(result.oneTimeCount, 0);
    expect(result.completeCount, 0);
    expect(result.totalAmount, 0);
    expect(result.paidAmount, 0);
    expect(result.unpaidAmount, 0);
    expect(result.overdueAmount, 0);
    expect(result.monthlySummaries, isEmpty);

    verify(() => mockRepository.getDues()).called(1);
  });
}
