import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';

abstract class TeamRepository {
  Future<Either<Failure, List<Team>>> getTeams();
}
