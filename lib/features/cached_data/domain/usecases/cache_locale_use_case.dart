import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/cache_repository.dart';

class CacheLocaleUseCase {
  final CacheRepository repository;

  CacheLocaleUseCase({required this.repository});

  Future<Either<Failure, Unit>> call({required String locale}) async {
    return await repository.cacheLocale(locale: locale);
  }
}
