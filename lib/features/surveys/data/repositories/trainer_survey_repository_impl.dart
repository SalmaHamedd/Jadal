import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/surveys/data/models/survey_details_model.dart';
import 'package:jadal_app/features/surveys/data/models/survey_model.dart';
import 'package:jadal_app/features/surveys/data/models/survey_results_model.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_details.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_question_input.dart';
import 'package:jadal_app/features/surveys/domain/entities/survey_results.dart';
import 'package:jadal_app/features/surveys/domain/repositories/trainer_survey_repository.dart';

class TrainerSurveyRepositoryImpl implements TrainerSurveyRepository {
  final http.Client client;

  TrainerSurveyRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  Future<String?> _token() => PreferencesDatabase().getToken();

  @override
  Future<Either<Failure, List<Survey>>> getTrainerSurveys({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final uri = Uri.parse(ApiConstants.trainerSurveysUrl).replace(
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

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        final surveys = data.map((item) => SurveyModel.fromJson(item)).toList();
        return Right(surveys);
      } else if (response.statusCode == 401) {
        return Left(AuthFailure(json['message'] ?? 'Unauthenticated'));
      } else if (response.statusCode == 403) {
        return Left(ForbiddenFailure(json['message'] ?? 'Unauthorized'));
      } else {
        return Left(ServerFailure(json['message'] ?? 'Failed to load surveys'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, SurveyDetails>> getTrainerSurveyDetails(int id) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.trainerSurveyDetailsUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(SurveyDetailsModel.fromJson(json['data']));
      } else if (response.statusCode == 401) {
        return Left(AuthFailure(json['message'] ?? 'Unauthenticated'));
      } else if (response.statusCode == 403) {
        return Left(ForbiddenFailure(json['message'] ?? 'Unauthorized'));
      } else if (response.statusCode == 404) {
        return Left(NotFoundFailure(json['message'] ?? 'Survey not found'));
      } else {
        return Left(ServerFailure(json['message'] ?? 'Failed to load survey'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Survey>> createTrainerSurvey({
    required String title,
    String? description,
    required List<int> teamIds,
    DateTime? closesAt,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final body = <String, dynamic>{
        'title': title,
        'team_ids': teamIds,
        if (description != null && description.isNotEmpty) 'description': description,
        if (closesAt != null) 'closes_at': closesAt.toUtc().toIso8601String(),
      };

      final response = await client.post(
        Uri.parse(ApiConstants.trainerSurveysUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          json['success'] == true) {
        return Right(SurveyDetailsModel.fromJson(json['data'] ?? {}));
      } else if (response.statusCode == 401) {
        return Left(AuthFailure(json['message'] ?? 'Unauthenticated'));
      } else if (response.statusCode == 403) {
        return Left(ForbiddenFailure(json['message'] ?? 'Unauthorized'));
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
        return Left(ServerFailure(json['message'] ?? 'Failed to create survey'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, SurveyResults>> getTrainerSurveyResults(int id) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.trainerSurveyResultsUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(SurveyResultsModel.fromJson(id, json['data'] ?? {}));
      } else if (response.statusCode == 401) {
        return Left(AuthFailure(json['message'] ?? 'Unauthenticated'));
      } else if (response.statusCode == 403) {
        return Left(ForbiddenFailure(json['message'] ?? 'Unauthorized'));
      } else if (response.statusCode == 404) {
        return Left(NotFoundFailure(json['message'] ?? 'Results not found'));
      } else {
        return Left(ServerFailure(json['message'] ?? 'Failed to load results'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, SurveyDetails>> updateTrainerSurvey({
    required int id,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? closesAt,
    bool clearClosesAt = false,
    List<int>? teamIds,
    List<SurveyQuestionInput>? questions,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (clearDescription) {
        body['description'] = null;
      } else if (description != null) {
        body['description'] = description;
      }
      if (clearClosesAt) {
        body['closes_at'] = null;
      } else if (closesAt != null) {
        body['closes_at'] = closesAt.toUtc().toIso8601String();
      }
      if (teamIds != null) body['team_ids'] = teamIds;
      if (questions != null) {
        body['questions'] = questions.map((q) => q.toJson()).toList();
      }

      final response = await client.put(
        Uri.parse(ApiConstants.trainerSurveyDetailsUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return Right(SurveyDetailsModel.fromJson(json['data']));
      } else if (response.statusCode == 401) {
        return Left(AuthFailure(json['message'] ?? 'Unauthenticated'));
      } else if (response.statusCode == 403) {
        return Left(ForbiddenFailure(json['message'] ?? 'Unauthorized'));
      } else if (response.statusCode == 404) {
        return Left(NotFoundFailure(json['message'] ?? 'Survey not found'));
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

  @override
  Future<Either<Failure, void>> deleteTrainerSurvey(int id) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.delete(
        Uri.parse(ApiConstants.trainerSurveyDetailsUrl(id)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        return const Right(null);
      } else if (response.statusCode == 401) {
        return Left(AuthFailure(json['message'] ?? 'Unauthenticated'));
      } else if (response.statusCode == 403) {
        return Left(ForbiddenFailure(json['message'] ?? 'Unauthorized'));
      } else if (response.statusCode == 404) {
        return Left(NotFoundFailure(json['message'] ?? 'Survey not found'));
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
