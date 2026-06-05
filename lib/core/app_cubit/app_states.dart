import 'package:flutter/material.dart';

@immutable
class AppState {
  final ThemeMode themeMode;
  final Locale locale;

  const AppState({
    required this.themeMode,
    required this.locale,
  });

  factory AppState.initial() => const AppState(
        themeMode: ThemeMode.system,
        locale: Locale('ar'),
      );

  AppState copyWith({ThemeMode? themeMode, Locale? locale}) => AppState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          locale == other.locale;

  @override
  int get hashCode => themeMode.hashCode ^ locale.hashCode;
}
