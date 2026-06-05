import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/debate_setup_repository.dart';

class GetAllTopicsUsecase {
  final DebateSetupRepository debateRepo;

  GetAllTopicsUsecase({required this.debateRepo});

  Future<Either<Failure, List<String>>> call() async {
    return await debateRepo.getAllTopics();
  }
}
