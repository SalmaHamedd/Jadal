import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:jadal_app/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:jadal_app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:jadal_app/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:jadal_app/features/splash/presentation/screens/splash_screen.dart';
import 'core/app_cubit/app_cubit.dart';
import 'core/app_cubit/app_states.dart';
import 'core/localization/l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'di/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones must stay portrait — the debate layouts (main speaker + team columns)
  // are designed vertically and a forced landscape overflows them.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  await di.init();
  await di.sl<AppCubit>().load();
  runApp(const JadalApp());
}

class JadalApp extends StatelessWidget {
  const JadalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AppCubit>()),
        BlocProvider(create: (_) => di.sl<SplashCubit>()..start()),
        BlocProvider(create: (_) => di.sl<LoginCubit>()),
        BlocProvider(create: (_) => di.sl<ForgotPasswordCubit>()),
      ],
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Jadal',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: state.themeMode,
            locale: state.locale,
            supportedLocales: AppCubit.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // The splash decides where to land: a stored token goes straight to
            // the main shell (bottom navigation), otherwise the login screen.
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
