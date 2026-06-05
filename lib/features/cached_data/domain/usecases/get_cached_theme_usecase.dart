import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/cache_repository.dart';

class GetCachedThemeUseCase {
  final CacheRepository repository;

  GetCachedThemeUseCase({required this.repository});

  Future<Either<Failure, String>> call() async {
    return await repository.getCachedTheme();
  }
}
