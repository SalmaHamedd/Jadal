import 'package:fpdart/fpdart.dart';

import '../../../../core/app_entities/motion_entity.dart';
import '../../../../core/error/failures.dart';

abstract class DebateSetupRepository {
  Future<Either<Failure, List<MotionEntity>>> getAllMotions();
  Future<Either<Failure, Unit>> addMotion(MotionEntity motion);
  Future<Either<Failure, List<String>>> getAllTopics();
}
