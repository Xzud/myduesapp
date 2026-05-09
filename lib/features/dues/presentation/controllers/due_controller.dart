import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_all_dues.dart';

class DueController extends ChangeNotifier {
  final GetAllDues getAllDues;

  DueController({required this.getAllDues});

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
}
