import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

// Auth Feature
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_saved_session_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Chord Detection Feature
import '../../features/chord_detection/data/datasources/chord_detection_remote_data_source.dart';
import '../../features/chord_detection/data/datasources/tflite_mlp_vision_data_source.dart';
import '../../features/chord_detection/data/repositories/chord_detection_repository_impl.dart';
import '../../features/chord_detection/domain/repositories/chord_detection_repository.dart';
import '../../features/chord_detection/domain/usecases/detect_chord_from_frame.dart';
import '../../features/chord_detection/domain/usecases/get_chord_guides.dart';
import '../../features/chord_detection/presentation/bloc/chord_detection_bloc.dart';

// Practice Drill Feature
import '../../features/practice_drill/data/datasources/practice_drill_remote_data_source.dart';
import '../../features/practice_drill/data/repositories/practice_drill_repository_impl.dart';
import '../../features/practice_drill/domain/repositories/practice_drill_repository.dart';
import '../../features/practice_drill/domain/usecases/evaluate_transition_drill.dart';
import '../../features/practice_drill/domain/usecases/get_drills.dart';
import '../../features/practice_drill/domain/usecases/get_practice_logs.dart';
import '../../features/practice_drill/domain/usecases/save_practice_log.dart';
import '../../features/practice_drill/presentation/bloc/practice_drill_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // -------------------------------------------------------------
  // External & Core Dependencies
  // -------------------------------------------------------------
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      client: sl(),
      prefs: sl(),
    ),
  );

  // -------------------------------------------------------------
  // Feature: Auth
  // -------------------------------------------------------------
  sl.registerFactory(
    () => AuthBloc(
      registerUseCase: sl(),
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getSavedSessionUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetSavedSessionUseCase(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      apiClient: sl(),
    ),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  // -------------------------------------------------------------
  // Feature: Chord Detection (MediaPipe Hands + TFLite MLP)
  // -------------------------------------------------------------
  sl.registerFactory(
    () => ChordDetectionBloc(
      repository: sl(),
      detectChordFromFrame: sl(),
    ),
  );

  sl.registerLazySingleton(() => DetectChordFromFrame(sl()));
  sl.registerLazySingleton(() => GetChordGuides(sl()));

  sl.registerLazySingleton<TfliteMlpVisionDataSource>(
    () => TfliteMlpVisionDataSourceImpl(),
  );
  sl.registerLazySingleton<ChordDetectionRemoteDataSource>(
    () => ChordDetectionRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ChordDetectionRepository>(
    () => ChordDetectionRepositoryImpl(
      visionDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // -------------------------------------------------------------
  // Feature: Practice Drill
  // -------------------------------------------------------------
  sl.registerFactory(
    () => PracticeDrillBloc(
      repository: sl(),
      getDrills: sl(),
      getPracticeLogs: sl(),
      savePracticeLog: sl(),
      evaluateTransitionDrill: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetDrills(sl()));
  sl.registerLazySingleton(() => GetPracticeLogs(sl()));
  sl.registerLazySingleton(() => SavePracticeLog(sl()));
  sl.registerLazySingleton(() => EvaluateTransitionDrill());

  sl.registerLazySingleton<PracticeDrillRemoteDataSource>(
    () => PracticeDrillRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<PracticeDrillRepository>(
    () => PracticeDrillRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );
}
