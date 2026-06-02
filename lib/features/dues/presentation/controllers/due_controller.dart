import 'package:flutter/foundation.dart';
import 'package:myduesapp/features/dues/application/usecases/delete_due.dart';
import 'package:myduesapp/features/dues/application/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/application/usecases/set_due_paid.dart';
import 'package:myduesapp/features/dues/application/usecases/update_due.dart';
import 'package:myduesapp/features/dues/domain/entities/due_entity.dart';

class DueController extends ChangeNotifier {
  final GetAllDues getAllDues;
  final SetDuePaid setDuePaid;
  final UpdateDue updateDue;
  final DeleteDue deleteDue;

  DueController({
    required this.getAllDues,
    required this.setDuePaid,
    required this.updateDue,
    required this.deleteDue,
  });

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
    await _runMutation(() async {
      await setDuePaid.call(dueId, paid);
      _dues = await getAllDues.call();
    });
  }

  Future<void> updateDueItem(DueEntity due) async {
    await _runMutation(() async {
      await updateDue.call(due);
      _dues = await getAllDues.call();
    });
  }

  Future<void> deleteDueItem(int dueId) async {
    await _runMutation(() async {
      await deleteDue.call(dueId);
      _dues = await getAllDues.call();
    });
  }

  Future<void> deleteDueItems(List<int> dueIds) async {
    final ids = dueIds.where((id) => id > 0).toSet().toList()..sort();
    if (ids.isEmpty) {
      return;
    }

    await _runMutation(() async {
      for (final id in ids) {
        await deleteDue.call(id);
      }
      _dues = await getAllDues.call();
    });
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        // ignore: avoid_print
        print('Due mutation failed: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
