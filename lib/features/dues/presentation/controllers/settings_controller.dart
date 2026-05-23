import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';

class SettingsController extends ChangeNotifier {
  final GetPaymentDates getPaymentDates;

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  SettingsController({required this.getPaymentDates});

  List<String> paymentDates = [];

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

  void addPaymentDate(String dateInput) {
    if (dateInput.isNotEmpty) {
      paymentDates.add(dateInput);
      // TODO connect to save in database
      dateInput = '';
      notifyListeners();
    }
  }

  void removePaymentDate(int index) {
    paymentDates.removeAt(index);
    // TODO connect to save in database
    notifyListeners();
  }
}
