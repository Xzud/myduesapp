import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class GetDueFilterState {
  final SettingsRepository repository;

  GetDueFilterState({required this.repository});

  Future<DueFilterState> call() async {
    return await repository.getDueFilterState();
  }
}
