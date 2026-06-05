import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../core/app_cubit/app_cubit.dart';
import '../core/network/network_info.dart';
import '../core/storage/preferences_database.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/forgot_password_cubit.dart';
import '../features/auth/presentation/cubit/login_cubit.dart';
import '../features/debates/data/repositories/mock_repositories.dart';
import '../features/debates/domain/repositories/debate_repositories.dart';
import '../features/live_debate/data/datasources/mock_live_debate_data.dart';
import '../features/live_debate/presentation/cubits/connection_cubit.dart';
import '../features/live_debate/presentation/cubits/debate_cubit.dart';
import '../features/splash/data/permissions_service.dart';
import '../features/splash/presentation/cubit/splash_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Cubits — app-wide
  sl.registerLazySingleton(() => AppCubit(prefs: sl()));

  //! Cubits — feature factories
  sl.registerFactory(() => SplashCubit(prefs: sl(), permissions: sl()));
  sl.registerFactory(() => LoginCubit(sl<AuthRepository>()));
  sl.registerFactory(() => ForgotPasswordCubit(sl<AuthRepository>()));

  //! Live-debate feature (mock-backed for now)
  sl.registerLazySingleton<MockLiveDebateData>(() => const MockLiveDebateData());
  sl.registerFactory(() => DebateCubit(data: sl<MockLiveDebateData>()));
  sl.registerFactory(() => ConnectionCubit());

  //! Auth repository — abstract bound to Mock (swap to ApiAuthRepository in one line)
  sl.registerLazySingleton<AuthRepository>(() => ApiAuthRepository());

  //! Debate-feature repositories — abstract bound to Mock for now
  sl.registerLazySingleton<DebatesRepository>(() => MockDebatesRepository());
  sl.registerLazySingleton<PreparationRoomRepository>(
          () => MockPreparationRoomRepository());
  sl.registerLazySingleton<LiveSessionRepository>(
          () => MockLiveSessionRepository());
  sl.registerLazySingleton<ScoringRepository>(() => MockScoringRepository());
  sl.registerLazySingleton<CoachRepository>(() => MockCoachRepository());
  sl.registerLazySingleton<StatisticsRepository>(
          () => MockStatisticsRepository());

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => PreferencesDatabase());
  sl.registerLazySingleton(() => PermissionsService());

  //! External
  sl.registerFactory(() => http.Client());
  sl.registerFactory(() => InternetConnectionChecker());
}