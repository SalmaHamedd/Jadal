import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

abstract class CacheRepository {
  Future<Either<Failure, String>> getCachedTheme();
  Future<Either<Failure, Unit>> cacheTheme({required String theme});
  Future<Either<Failure, String>> getCachedLocale();
  Future<Either<Failure, Unit>> cacheLocale({required String locale});
}
