import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/domain/usecases/reset_all_data.dart';
import 'package:myduesapp/features/dues/domain/usecases/set_payment_dates.dart';

class SettingsController extends ChangeNotifier {
  final GetPaymentDates getPaymentDates;
  final SetPaymentDates setPaymentDates;
  final ResetAllData resetAllData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SettingsController({
    required this.getPaymentDates,
    required this.setPaymentDates,
    required this.resetAllData,
  });

  List<int> _billingDays = [];
  List<int> get billingDays => List.unmodifiable(_billingDays);

  Future<void> fetchPaymentDates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await getPaymentDates.call();
      final days = <int>[];
      for (final v in raw) {
        final d = int.tryParse(v);
        if (d != null) days.add(d);
      }
      days.sort();
      _billingDays = days.toSet().toList()..sort();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBillingDay(int day) async {
    if (day < 1 || day > 31) {
      _errorMessage = 'Billing day must be between 1 and 31';
      notifyListeners();
      return;
    }

    final next = {..._billingDays, day}.toList()..sort();
    await _persist(next);
  }

  Future<void> removeBillingDay(int day) async {
    final next = _billingDays.where((d) => d != day).toList()..sort();
    await _persist(next);
  }

  Future<void> resetData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await resetAllData.call();
      _billingDays = [];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist(List<int> next) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await setPaymentDates.call(next);
      _billingDays = next;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
