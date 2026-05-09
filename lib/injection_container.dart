import 'package:get_it/get_it.dart' show GetIt;
import 'package:myduesapp/core/database/database_helper.dart'
    show DatabaseHelper;
import 'package:myduesapp/features/dues/data/datasources/due_datasource.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/data/repositories/implementations/due_repository_impl.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:sqflite/sqflite.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final db = await DatabaseHelper.instance.database;
  sl.registerLazySingleton<Database>(() => db);

  sl.registerLazySingleton<DueDatasource>(
    () => DueDatasourceImpl(database: sl()),
  );

  sl.registerLazySingleton<DueRepository>(
    () => DueRepositoryImpl(datasource: sl()),
  );

  sl.registerLazySingleton<GetAllDues>(() => GetAllDues(repository: sl()));

  sl.registerFactory(() => DueController(getAllDues: sl()));
}
