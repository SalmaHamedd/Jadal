import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/search/domain/entities/search_user.dart';
import 'package:jadal_app/features/search/domain/entities/search_team.dart';
import 'package:jadal_app/features/search/domain/repositories/search_repository.dart';
import 'package:jadal_app/features/search/data/models/search_response_model.dart';
import 'package:jadal_app/core/services/session_guard.dart';

class SearchRepositoryImpl implements SearchRepository {
  final http.Client client;

  SearchRepositoryImpl({http.Client? client})
      : client = client ?? http.Client();

  @override
  Future<Either<Failure, (List<SearchUser>, List<SearchTeam>)>> search({
    required String query,
    int perPage = 15,
    int usersPage = 1,
    int teamsPage = 1,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final uri = Uri.parse(ApiConstants.searchUrl).replace(
        queryParameters: {
          'q': query,
          'per_page': perPage.toString(),
          'users_page': usersPage.toString(),
          'teams_page': teamsPage.toString(),
        },
      );
      
      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final model = SearchResponseModel.fromJson(json);
          return Right((model.users, model.teams));
        } else {
          return Left(ServerFailure(json['message'] ?? 'Search failed'));
        }
      } else if (response.statusCode == 401) {
        // Rejected token: clear the session and return to login.
        SessionGuard.onUnauthorized();
        return Left(AuthFailure('Unauthenticated'));
      } else if (response.statusCode == 422) {
        final body = jsonDecode(response.body);
        return Left(ValidationFailure(body['message'] ?? 'Invalid query'));
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}