import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../core/app_cubit/app_cubit.dart';
import '../core/network/network_info.dart';
import '../core/services/deep_link_service.dart';
import '../core/storage/preferences_database.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/forgot_password_cubit.dart';
import '../features/auth/presentation/cubit/login_cubit.dart';
import '../features/live_debate/data/repositories/live_debate_repository.dart';
import '../features/live_debate/data/repositories/live_debate_repository_impl.dart';
import '../features/live_debate/debate_mode_config.dart';
import '../features/live_debate/presentation/cubits/connection_cubit.dart';
import '../features/live_debate/presentation/cubits/debate_controller.dart';
import '../features/live_debate/presentation/cubits/live_debate_cubit.dart';
import '../features/notifications/data/device_repository.dart';
import '../features/notifications/data/push_service.dart';
import '../features/profile/data/repositories/profile_repository.dart';
import '../features/splash/data/permissions_service.dart';
import '../features/statistics/data/repositories/debater_stats_repository.dart';
import '../features/statistics/data/repositories/debater_stats_repository_impl.dart';
import '../features/statistics/data/repositories/leaderboard_repository.dart';
import '../features/splash/presentation/cubit/splash_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Cubits — app-wide
  sl.registerLazySingleton(() => AppCubit(prefs: sl()));

  //! Cubits — feature factories
  sl.registerFactory(() => SplashCubit(prefs: sl(), permissions: sl()));
  sl.registerFactory(() => LoginCubit(sl<AuthRepository>()));
  sl.registerFactory(() => ForgotPasswordCubit(sl<AuthRepository>()));

  //! Live-debate feature (backend only — the mock/test peer-to-peer mode is gone).
  sl.registerLazySingleton<LiveDebateRepository>(() => LiveDebateRepositoryImpl());
  sl.registerLazySingleton(() => ProfileRepository());
  // Debater statistics (read-only API).
  sl.registerLazySingleton<DebaterStatsRepository>(() => DebaterStatsRepositoryImpl());
  // Public leaderboards (home preview + public stats screen).
  sl.registerLazySingleton(() => LeaderboardRepository());
  // FCM device-token registry (POST/DELETE /api/devices) + the FCM
  // lifecycle owner. PushService is a singleton because it holds the message
  // stream subscriptions and the last-registered locale.
  sl.registerLazySingleton(() => DeviceRepository());
  sl.registerLazySingleton(() => PushService(devices: sl<DeviceRepository>()));
  // Owns the app-links subscription for the whole session.
  sl.registerLazySingleton(() => DeepLinkService());
  // param1 = which debate to load (null falls back to the dev debate id).
  // param2 = join as a tokenless guest from a share link.
  sl.registerFactoryParam<DebateController, int?, bool?>(
    (debateId, asGuest) => LiveDebateCubit(
      repo: sl<LiveDebateRepository>(),
      profileRepo: sl<ProfileRepository>(),
      debateId: debateId ?? DebateModeConfig.devDebateId,
      asGuest: asGuest ?? false,
    ),
  );
  sl.registerFactory(() => ConnectionCubit());

  //! Auth repository — abstract bound to Mock (swap to ApiAuthRepository in one line)
  sl.registerLazySingleton<AuthRepository>(() => ApiAuthRepository());

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => PreferencesDatabase());
  sl.registerLazySingleton(() => PermissionsService());

  //! External
  sl.registerFactory(() => http.Client());
  sl.registerFactory(() => InternetConnectionChecker());
}