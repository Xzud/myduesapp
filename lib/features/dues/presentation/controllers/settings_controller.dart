import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';

class SettingsController extends ChangeNotifier {
  final GetPaymentDates getPaymentDates;

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SettingsController({required this.getPaymentDates});

  List<String> paymentDates = [];
  String dateInput = '';

  Future<void> fetchPaymentDates() async {
    try {
      paymentDates = await getPaymentDates();
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Error fetching payment dates: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  void addPaymentDate() {
    if (dateInput.isNotEmpty) {
      paymentDates.add(dateInput);
      dateInput = '';
      notifyListeners();
    }
  }

  void removePaymentDate(int index) {
    paymentDates.removeAt(index);
    notifyListeners();
  }

  void updateDateInput(String value) {
    dateInput = value;
    notifyListeners();
  }
}
