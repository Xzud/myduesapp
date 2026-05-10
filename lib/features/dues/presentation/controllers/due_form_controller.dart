import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';

class DueFormController extends ChangeNotifier {
  final GetPaymentDates getPaymentDates;

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DueFormController({required this.getPaymentDates});
}
