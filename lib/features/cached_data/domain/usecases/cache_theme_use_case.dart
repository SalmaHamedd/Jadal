import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/cache_repository.dart';

class CacheThemeUseCase {
  final CacheRepository repository;

  CacheThemeUseCase({required this.repository});

  Future<Either<Failure, Unit>> call({required String theme}) async {
    return await repository.cacheTheme(theme: theme);
  }
}
