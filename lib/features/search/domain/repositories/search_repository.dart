import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/search/domain/entities/search_user.dart';
import 'package:jadal_app/features/search/domain/entities/search_team.dart';

abstract class SearchRepository {
  Future<Either<Failure, (List<SearchUser>, List<SearchTeam>)>> search({
    required String query,
    int perPage = 15,
    int usersPage = 1,
    int teamsPage = 1,
  });
}