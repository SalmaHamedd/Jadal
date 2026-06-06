part of 'splash_cubit.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => const [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

class SplashNavigateToHome extends SplashState {
  const SplashNavigateToHome();
}

class SplashNavigateToPermissions extends SplashState {
  final List<AppPermission> deniedPermissions;
  const SplashNavigateToPermissions(this.deniedPermissions);

  @override
  List<Object?> get props => [deniedPermissions];
}
