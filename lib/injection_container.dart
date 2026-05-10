import 'package:get_it/get_it.dart' show GetIt;
import 'package:myduesapp/core/database/database_helper.dart'
    show DatabaseHelper;
import 'package:myduesapp/features/dues/data/datasources/due_datasource.dart';
import 'package:myduesapp/features/dues/data/datasources/settings_datasource.dart';
import 'package:myduesapp/features/dues/data/repositories/due_repository.dart';
import 'package:myduesapp/features/dues/data/repositories/implementations/due_repository_impl.dart';
import 'package:myduesapp/features/dues/data/repositories/implementations/settings_repository_impl.dart';
import 'package:myduesapp/features/dues/data/repositories/settings_repository.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_all_dues.dart';
import 'package:myduesapp/features/dues/domain/usecases/get_payment_dates.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_controller.dart';
import 'package:myduesapp/features/dues/presentation/controllers/due_form_controller.dart';
import 'package:sqflite/sqflite.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final db = await DatabaseHelper.instance.database;
  sl.registerLazySingleton<Database>(() => db);

  // DATA SOURCES
  sl.registerLazySingleton<DueDatasource>(
    () => DueDatasourceImpl(database: sl()),
  );
  sl.registerLazySingleton<SettingsDatasource>(
    () => SettingsDatasourceImpl(database: sl()),
  );

  // DATA REPOSITORIES
  sl.registerLazySingleton<DueRepository>(
    () => DueRepositoryImpl(datasource: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(datasource: sl()),
  );

  // USECASES
  sl.registerLazySingleton<GetAllDues>(() => GetAllDues(repository: sl()));
  sl.registerLazySingleton<GetPaymentDates>(
    () => GetPaymentDates(repository: sl()),
  );

  // CONTROLLERs
  sl.registerFactory(() => DueController(getAllDues: sl()));
  sl.registerFactory(() => DueFormController(getPaymentDates: sl()));
}
