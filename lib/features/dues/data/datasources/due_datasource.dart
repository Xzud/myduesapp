import 'package:myduesapp/features/dues/data/%20models/due_model.dart'
    show DueModel;
import 'package:sqflite/sqflite.dart';

abstract class DueDatasource {
  Future<List<DueModel>> getDues();
}

class DueDatasourceImpl implements DueDatasource {
  Database database;

  DueDatasourceImpl({required this.database});

  @override
  Future<List<DueModel>> getDues() async {
    var result = await database.query('dues');

    List<DueModel> dues = [];

    if (result.isEmpty) {
      print('No dues found');

      return [];
    }

    for (var item in result) {
      DueModel currentDue = DueModel.fromMap(item);
      
      dues.add(currentDue);
    }
    return dues;
  }
}
