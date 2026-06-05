import 'package:fpdart/fpdart.dart';

import '../../../../core/app_entities/motion_entity.dart';
import '../../../../core/app_models/motion_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/debate_setup_repository.dart';
import '../datasources/debate_setup_remote_datasource.dart';

class DebateSetupRepositoryImpl extends DebateSetupRepository {
  final NetworkInfo networkInfo;
  final DebateSetupRemoteDatasource remoteDatasource;

  DebateSetupRepositoryImpl({
    required this.networkInfo,
    required this.remoteDatasource,
  });

  @override
  Future<Either<Failure, Unit>> addMotion(MotionEntity motion) async {
    final motionModel =
        MotionModel(title: motion.title, topics: motion.topics);
    if (await networkInfo.isConnected) {
      try {
        await remoteDatasource.addMotion(motionModel);
        return const Right(unit);
      } on ServerException {
        return const Left(ServerFailure());
      }
    } else {
      return const Left(OfflineFailure());
    }
  }

  @override
  Future<Either<Failure, List<MotionEntity>>> getAllMotions() async {
    try {
      final remoteMotions = await remoteDatasource.getAllMotions();
      return Right(remoteMotions);
    } on ServerException {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAllTopics() async {
    try {
      final remoteTopics = await remoteDatasource.getAllTopics();
      return Right(remoteTopics);
    } on ServerException {
      return const Left(ServerFailure());
    }
  }
}
