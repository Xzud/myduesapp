import 'package:myduesapp/features/dues/data/%20models/due_model.dart';

abstract class DueRepository {
  Future<List<DueModel>> getDues();
}
