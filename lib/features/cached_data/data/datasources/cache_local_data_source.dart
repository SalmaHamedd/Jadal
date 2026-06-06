import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/storage/preferences_database.dart';

abstract class CacheLocalDataSource {
  Future<String?> getCachedTheme();
  Future<String?> getCachedLocale();
  Future<Unit> cacheTheme({required String theme});
  Future<Unit> cacheLocale({required String locale});
}

class CacheLocalDataSourceImpl extends CacheLocalDataSource {
  final PreferencesDatabase db;

  CacheLocalDataSourceImpl({required this.db});

  @override
  Future<Unit> cacheLocale({required String locale}) async {
    await db.setValue('LOCALE', locale);
    return Future.value(unit);
  }

  @override
  Future<Unit> cacheTheme({required String theme}) async {
    await db.setValue('THEME_MODE', theme);
    return Future.value(unit);
  }

  @override
  Future<String?> getCachedLocale() async {
    final String? locale = await db.getValue<String>('LOCALE');
    return Future.value(locale);
  }

  @override
  Future<String?> getCachedTheme() async {
    final String? theme = await db.getValue<String>('THEME_MODE');
    return Future.value(theme);
  }
}
