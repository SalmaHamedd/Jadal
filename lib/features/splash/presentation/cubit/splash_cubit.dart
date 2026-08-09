import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/preferences_database.dart';
import '../../../home/data/home_prefetch.dart';
import '../../data/permissions_service.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final PreferencesDatabase _prefs;
  final PermissionsService _permissions;
  static const Duration _minDisplay = Duration(seconds: 6);

  SplashCubit({
    required PreferencesDatabase prefs,
    required PermissionsService permissions,
  })  : _prefs = prefs,
        _permissions = permissions,
        super(const SplashInitial());

  Future<void> start() async {
    final stopwatch = Stopwatch()..start();

    // §4.1 — warm the home screen's data while the splash animation plays,
    // so the post-splash screen renders content rather than spinners. Only
    // when signed in: without a token the calls would just 401.
    final token = await _prefs.getToken();
    if (token != null && token.isNotEmpty) HomePrefetch.start();

    final result = await _permissions.requestLiveDebatePermissions();

    // §7 — ask for notifications at first launch, after the debate-critical
    // permissions so the essential prompts come first. The result is
    // deliberately discarded and never feeds the gating below: declining push
    // must not block entry to the app.
    await _permissions.requestNotifications();

    final elapsed = stopwatch.elapsed;
    if (elapsed < _minDisplay) {
      await Future.delayed(_minDisplay - elapsed);
    }

    if (result.anyPermanentlyDenied) {
      emit(SplashNavigateToPermissions(result.denied));
      return;
    }

    if (token != null && token.isNotEmpty) {
      emit(const SplashNavigateToHome());
    } else {
      emit(const SplashNavigateToLogin());
    }
  }
}