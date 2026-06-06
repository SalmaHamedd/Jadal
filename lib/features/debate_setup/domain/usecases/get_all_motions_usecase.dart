import 'package:fpdart/fpdart.dart';

import '../../../../core/app_entities/motion_entity.dart';
import '../../../../core/error/failures.dart';
import '../repositories/debate_setup_repository.dart';

class GetAllMotionsUsecase {
  final DebateSetupRepository debateRepo;

  GetAllMotionsUsecase({required this.debateRepo});

  Future<Either<Failure, List<MotionEntity>>> call() async {
    return await debateRepo.getAllMotions();
  }
}
