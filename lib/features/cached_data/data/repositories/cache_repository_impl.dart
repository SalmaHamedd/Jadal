import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/cache_repository.dart';
import '../datasources/cache_local_data_source.dart';

class CacheRepositoryImpl extends CacheRepository {
  final CacheLocalDataSource dataSource;

  CacheRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Unit>> cacheLocale({required String locale}) async {
    return await _caching(() {
      return dataSource.cacheLocale(locale: locale);
    });
  }

  @override
  Future<Either<Failure, Unit>> cacheTheme({required String theme}) async {
    return await _caching(() {
      return dataSource.cacheTheme(theme: theme);
    });
  }

  @override
  Future<Either<Failure, String>> getCachedLocale() async {
    try {
      final String locale = 'en';//await dataSource.getCachedLocale() ?? 'en';
      return Right(locale);
    } on EmptyCacheException {
      return const Left(EmptyCacheFailure());
    }
  }

  @override
  Future<Either<Failure, String>> getCachedTheme() async {
    try {
      final String theme = 'Light';//await dataSource.getCachedTheme() ?? 'Light';
      return Right(theme);
    } on EmptyCacheException {
      return const Left(EmptyCacheFailure());
    }
  }

  Future<Either<Failure, Unit>> _caching(
      Future<Unit> Function() cacheFunction) async {
    try {
      await cacheFunction();
      return const Right(unit);
    } on EmptyCacheException {
      return const Left(EmptyCacheFailure());
    }
  }
}
