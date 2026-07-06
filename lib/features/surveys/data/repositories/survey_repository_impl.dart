import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/surveys/data/models/survey_details_model.dart';
import 'package:jadal_app/features/surveys/data/models/survey_model.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/repositories/survey_repository.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  final http.Client client;

  SurveyRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<Either<Failure, List<Survey>>> getSurveys({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final uri = Uri.parse(ApiConstants.surveysUrl).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
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
          final List<dynamic> data = json['data'];
          final surveys = data.map((item) => SurveyModel.fromJson(item)).toList();
          return Right(surveys);
        } else {
          return Left(ServerFailure(json['message'] ?? 'Failed to load surveys'));
        }
      } else if (response.statusCode == 401) {
        return Left(AuthFailure('Unauthenticated'));
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, SurveyDetails>> getSurveyDetails(int id) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.surveyDetailsUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final details = SurveyDetailsModel.fromJson(json['data']);
          return Right(details);
        } else {
          return Left(ServerFailure(json['message'] ?? 'Failed to load survey'));
        }
      } else if (response.statusCode == 401) {
        return Left(AuthFailure('Unauthenticated'));
      } else if (response.statusCode == 404) {
        return Left(NotFoundFailure('Survey not found'));
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> submitSurveyResponse({
    required int surveyId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.post(
        Uri.parse(ApiConstants.surveyRespondUrl(surveyId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'answers': answers}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (json['success'] == true) {
          return const Right(null);
        } else {
          return Left(ServerFailure(json['message'] ?? 'Failed to submit response'));
        }
      } else if (response.statusCode == 401) {
        return Left(AuthFailure('Unauthenticated'));
      } else if (response.statusCode == 422) {
        final errorsRaw = json['errors'];
        Map<String, List<String>>? errors;
        if (errorsRaw is Map) {
          errors = errorsRaw.map(
            (key, value) => MapEntry(
              key.toString(),
              (value as List).map((e) => e.toString()).toList(),
            ),
          );
        }
        return Left(
          ValidationFailure(json['message'] ?? 'Validation error', errors: errors),
        );
      } else {
        return Left(
          ServerFailure(json['message'] ?? 'Server error: ${response.statusCode}'),
        );
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
