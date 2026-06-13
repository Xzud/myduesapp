import 'package:myduesapp/features/dues/domain/entities/due_filter_state.dart';
import 'package:myduesapp/features/dues/domain/repositories/settings_repository.dart';

class SetDueFilterState {
  final SettingsRepository repository;

  SetDueFilterState({required this.repository});

  Future<void> call(DueFilterState state) async {
    await repository.setDueFilterState(state);
  }
}
