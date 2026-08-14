import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/complaints/data/models/complaint_model.dart';
import 'package:jadal_app/features/complaints/domain/entities/complaint.dart';
import 'package:jadal_app/features/complaints/domain/repositories/complaint_repository.dart';
import 'package:jadal_app/core/services/session_guard.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  final http.Client client;

  ComplaintRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  Future<String?> _token() => PreferencesDatabase().getToken();

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Failure _failureFor(int statusCode, Map<String, dynamic> json, String fallback) {
    switch (statusCode) {
      case 401:
        // Rejected token: clear the session and return to login,
        // instead of leaving the user in an app where nothing works.
        SessionGuard.onUnauthorized();
        return AuthFailure(json['message'] ?? 'Unauthenticated');
      case 403:
        return ForbiddenFailure(json['message'] ?? 'Unauthorized');
      case 404:
        return NotFoundFailure(json['message'] ?? 'Not found');
      case 422:
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
        return ValidationFailure(json['message'] ?? 'Validation error', errors: errors);
      default:
        return ServerFailure(json['message'] ?? fallback);
    }
  }

  @override
  Future<Either<Failure, List<Complaint>>> getMyComplaints() async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.myComplaintsUrl),
        headers: await _headers(),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final List<dynamic> data = json['data'] ?? [];
        return Right(data.map((item) => ComplaintModel.fromJson(item)).toList());
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to load complaints'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Complaint>> fileComplaint({
    required String description,
    required int debateId,
    int? targetUserId,
    String? targetRole,
  }) async {
    try {
      final token = await _token();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.post(
        Uri.parse(ApiConstants.complaintsUrl),
        headers: await _headers(),
        body: jsonEncode({
          'description': description,
          'debate_id': debateId,
          'target_user_id': ?targetUserId,
          'target_role': ?targetRole,
        }),
      );

      final json = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          json['success'] == true) {
        return Right(ComplaintModel.fromJson(json['data'] ?? {}));
      }
      return Left(_failureFor(response.statusCode, json, 'Failed to file complaint'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
