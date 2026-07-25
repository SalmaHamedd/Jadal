import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/teams/data/models/team_model.dart';
import 'package:jadal_app/features/teams/domain/entities/team.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';

class TeamRepositoryImpl implements TeamRepository {
  final http.Client client;

  TeamRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<Either<Failure, List<Team>>> getTeams() async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.teamsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        final teams = data.map((item) => TeamModel.fromJson(item)).toList();
        return Right(teams);
      } else if (response.statusCode == 401) {
        return Left(AuthFailure(json['message'] ?? 'Unauthenticated'));
      } else if (response.statusCode == 403) {
        return Left(ForbiddenFailure(json['message'] ?? 'Unauthorized'));
      } else {
        return Left(ServerFailure(json['message'] ?? 'Failed to load teams'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
