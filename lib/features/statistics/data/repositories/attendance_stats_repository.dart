import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/token_storage.dart';
import '../models/attendance_stat_model.dart';

enum AttendanceRole { debater, trainer, judge }

/// Read-only access to the three attendance endpoints (sprinkles §6.5):
/// `/debaters/{id}/stats/prep-attendance`, `/trainers/{id}/stats/attendance`,
/// `/judges/{id}/stats/attendance`. Same auth policy as the debater stats:
/// self, admin, or the coach currently supervising the target.
class AttendanceStatsRepository {
  final http.Client _client;
  AttendanceStatsRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _urlFor(AttendanceRole role, int userId) => switch (role) {
        AttendanceRole.debater => ApiConstants.prepAttendanceUrl(userId),
        AttendanceRole.trainer => ApiConstants.trainerAttendanceUrl(userId),
        AttendanceRole.judge => ApiConstants.judgeAttendanceUrl(userId),
      };

  Future<Either<Failure, AttendanceStat>> getAttendance(
    AttendanceRole role,
    int userId,
  ) async {
    try {
      final uri = Uri.parse(_urlFor(role, userId));
      final res = await _client.get(uri, headers: await _headers());
      Map<String, dynamic>? body;
      if (res.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) body = decoded;
        } catch (_) {/* non-JSON body */}
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = body?['data'];
        if (data is! Map) return const Left(ServerFailure('Unexpected empty response'));
        return Right(AttendanceStat.fromJson(data.cast<String, dynamic>()));
      }
      final message = body?['message'] as String?;
      switch (res.statusCode) {
        case 403:
          return Left(ForbiddenFailure(message ?? 'Forbidden'));
        case 404:
          return Left(NotFoundFailure(message ?? 'Not found'));
        default:
          return Left(ServerFailure(message ?? 'Server error (${res.statusCode})'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
