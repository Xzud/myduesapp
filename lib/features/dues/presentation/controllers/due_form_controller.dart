import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/application/usecases/create_split_due.dart';
import 'package:myduesapp/features/dues/application/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/domain/entities/interest_plan.dart';

enum AmountInputMode { principal, monthly }

class InstallmentPreview {
  final int index;
  final int count;
  final double amount;
  final DateTime dueDate;

  const InstallmentPreview({
    required this.index,
    required this.count,
    required this.amount,
    required this.dueDate,
  });
}

class DueFormController extends ChangeNotifier {
  final GetPaymentDates getPaymentDates;
  final CreateSplitDue createSplitDue;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DueFormController({
    required this.getPaymentDates,
    required this.createSplitDue,
  });

  Future<List<int>> loadBillingDays() async {
    final values = await getPaymentDates.call();
    final days = <int>[];
    for (final v in values) {
      final d = int.tryParse(v);
      if (d != null) days.add(d);
    }
    days.sort();
    return days.toSet().toList()..sort();
  }

  double resolveSplitAmount({
    required double inputAmount,
    required int installmentCount,
    required AmountInputMode amountMode,
  }) {
    if (amountMode == AmountInputMode.monthly) {
      return inputAmount * installmentCount;
    }
    return inputAmount;
  }

  // Backward-compatible API used by existing unit tests.
  Future<void> createLoanSplit({
    required String name,
    required double amount,
    required int installmentCount,
    DateTime? startDate,
    InterestPlan? interestPlan,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final billingDays = await loadBillingDays();
      await createSplitDue.call(
        name: name,
        amount: amount,
        installmentCount: installmentCount,
        billingDays: billingDays,
        startDate: startDate,
        interestPlan: interestPlan,
      );
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error creating loan split: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<InstallmentPreview> buildPreview({
    required double amount,
    required int installmentCount,
    required List<int> billingDays,
    DateTime? startDate,
  }) {
    if (installmentCount < 1) return const [];

    final cleanDays =
        billingDays.toSet().where((d) => d >= 1 && d <= 31).toList()..sort();
    if (cleanDays.isEmpty) return const [];

    final cents = (amount * 100).round();
    final base = cents ~/ installmentCount;
    final remainder = cents % installmentCount;

    final firstDate = startDate ?? DateTime.now();
    DateTime cursor = DateTime(firstDate.year, firstDate.month, firstDate.day);

    final out = <InstallmentPreview>[];
    for (int i = 0; i < installmentCount; i++) {
      final dueDate = _nextDueDate(cursor, cleanDays);
      final installmentCents = i == installmentCount - 1
          ? base + remainder
          : base;
      out.add(
        InstallmentPreview(
          index: i + 1,
          count: installmentCount,
          amount: installmentCents / 100,
          dueDate: dueDate,
        ),
      );
      cursor = dueDate.add(const Duration(days: 1));
    }

    return out;
  }

  Future<void> submitSplitDue({
    required String name,
    required double inputAmount,
    required int installmentCount,
    required List<int> billingDays,
    DateTime? startDate,
    AmountInputMode amountMode = AmountInputMode.principal,
    InterestPlan? interestPlan,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final amount = resolveSplitAmount(
        inputAmount: inputAmount,
        installmentCount: installmentCount,
        amountMode: amountMode,
      );
      await createSplitDue.call(
        name: name,
        amount: amount,
        installmentCount: installmentCount,
        billingDays: billingDays,
        startDate: startDate,
        interestPlan: interestPlan,
      );
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error creating split due: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _nextDueDate(DateTime from, List<int> billingDays) {
    DateTime monthCursor = DateTime(from.year, from.month, 1);

    while (true) {
      for (final day in billingDays) {
        final maxDay = DateTime(monthCursor.year, monthCursor.month + 1, 0).day;
        final clampedDay = day > maxDay ? maxDay : day;
        final candidate = DateTime(
          monthCursor.year,
          monthCursor.month,
          clampedDay,
        );
        final fromDateOnly = DateTime(from.year, from.month, from.day);
        if (!candidate.isBefore(fromDateOnly)) {
          return candidate;
        }
      }
      monthCursor = DateTime(monthCursor.year, monthCursor.month + 1, 1);
    }
  }
}
