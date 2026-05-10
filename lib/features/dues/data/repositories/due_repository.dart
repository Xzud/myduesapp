import 'package:myduesapp/features/dues/data/models/due_model.dart';

abstract class DueRepository {
  Future<List<DueModel>> getDues();
}
