import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/injection_container.dart' as di;
import '../../features/notifications/data/push_service.dart';
import '../storage/preferences_database.dart';
import 'app_states.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit({required PreferencesDatabase prefs})
      : _prefs = prefs,
        super(AppState.initial());

  final PreferencesDatabase _prefs;

  static const _themeKey = 'jadal_theme_mode';
  static const _localeKey = 'jadal_locale';
  static const supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  Future<void> load() async {
    final theme = _decodeThemeMode(await _prefs.getValue<String>(_themeKey));
    final locale = _decodeLocale(await _prefs.getValue<String>(_localeKey));
    emit(state.copyWith(themeMode: theme, locale: locale));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _prefs.setValue(_themeKey, _encodeThemeMode(mode));
  }

  Future<void> toggleTheme(Brightness platformBrightness) async {
    final isDark = state.themeMode == ThemeMode.dark ||
        (state.themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setLocale(Locale locale) async {
    emit(state.copyWith(locale: locale));
    await _prefs.setValue(_localeKey, locale.languageCode);
    // The backend localises each push from the locale stored against the
    // device, so a language switch must be pushed to the server or the user
    // keeps receiving notifications in the language they just left.
    // No-op when logged out or when Firebase failed to start.
    await di.sl<PushService>().updateLocale(locale.languageCode);
  }

  Future<void> toggleLocale() async {
    final next = state.locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    await setLocale(next);
  }

  static String _encodeThemeMode(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  static ThemeMode _decodeThemeMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static Locale _decodeLocale(String? raw) {
    if (raw == 'en') return const Locale('en');
    return const Locale('ar');
  }
}
