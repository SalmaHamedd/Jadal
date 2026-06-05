import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/preferences_database.dart';
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

    final result = await _permissions.requestLiveDebatePermissions();

    final token = await _prefs.getToken();
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