import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/data/models/due_model.dart'
    show DueModel;
import 'package:myduesapp/features/dues/domain/usecases/create_due.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';

class DueFormController extends ChangeNotifier {
  final GetPaymentDates getPaymentDates;
  final CreateDue createDueUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DueFormController({
    required this.getPaymentDates,
    required this.createDueUseCase,
  });

  Future<void> createDue(DueModel due) async {
    _isLoading = true;
    notifyListeners();
    try {
      await createDueUseCase(due);
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Error creating due: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
