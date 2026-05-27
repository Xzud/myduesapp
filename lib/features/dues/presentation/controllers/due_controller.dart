import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/domain/usecases/set_due_paid.dart';

class DueController extends ChangeNotifier {
  final GetAllDues getAllDues;
  final SetDuePaid setDuePaid;

  DueController({required this.getAllDues, required this.setDuePaid});

  List<MonthlyDue> _dues = [];
  List<MonthlyDue> get dues => _dues;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDues() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dues = await getAllDues.call();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePaid({required int dueId, required bool paid}) async {
    // Optimistic local update.
    for (final month in _dues) {
      for (final due in month.dues) {
        if (due.id == dueId) {
          due.paid = paid;
        }
      }
    }
    notifyListeners();

    try {
      await setDuePaid.call(dueId, paid);
    } catch (e) {
      _errorMessage = e.toString();
      await fetchDues();
    }
  }
}
