import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/notifications/data/push_service.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';
import 'package:jadal_app/features/profile/data/models/profile_model.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/domain/entities/public_user_profile.dart';
import 'package:jadal_app/features/profile/domain/entities/team_membership.dart';

class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile() async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) {
        return Left(AuthFailure('No authentication token found'));
      }

      final response = await http.get(
        Uri.parse(ApiConstants.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        final profile = ProfileModel.fromJson(data);
        return Right(profile);
      }

      return Left(ServerFailure(message));
    } catch (e) {
      return Left(NetworkFailure('Network error'));
    }
  }

  Future<Either<Failure, Profile>> updateProfile({
    required String name,
    required String phone,
    String? birthDate,
    String? location,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) {
        return Left(AuthFailure('No authentication token found'));
      }

      final response = await http.put(
        Uri.parse(ApiConstants.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'birth_date': ?birthDate,
          'location': ?location,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        final updatedProfile = ProfileModel.fromJson(data);
        return Right(updatedProfile);
      }

      return Left(ServerFailure(message));
    } catch (e) {
      return Left(NetworkFailure('Network error'));
    }
  }

  Future<Either<Failure, String>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) {
        return Left(AuthFailure('No authentication token found'));
      }

      final response = await http.put(
        Uri.parse(ApiConstants.changePasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Right(message);
      } else {
        return Left(ServerFailure(message));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  Future<Either<Failure, String>> uploadAvatar(File imageFile) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('No token'));

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.avatarUrl),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          imageFile.path,
          contentType: http.MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final json = jsonDecode(responseBody);

      if (response.statusCode == 200 && json['success'] == true) {
        final newAvatarUrl = json['data']?['avatar_url'] ?? json['message'];
        return Right(newAvatarUrl.toString());
      } else {
        return Left(ServerFailure(json['message'] ?? 'Upload failed'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  // ── Public profile / achievements / team history (sprinkles §6) ────────────

  Future<Either<Failure, PublicUserProfile>> getUserProfile(int userId) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('No authentication token found'));

      final response = await http.get(
        Uri.parse(ApiConstants.userProfileUrl(userId)),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Right(PublicUserProfile.fromJson(responseBody['data']));
      }
      return Left(ServerFailure(responseBody['message'] ?? 'Unknown error'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  /// §6.8 — `sort` is `date` (assigned_at desc, backend default) or `rank`
  /// (gold → … → participation, recency within a tier). Response is
  /// `data: [...]` with a sibling `meta` pagination block (BACKEND_RESPONSE §0.2).
  Future<Either<Failure, List<Achievement>>> getUserAchievements(
    int userId, {
    int page = 1,
    int perPage = 15,
    String sort = 'date',
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('No authentication token found'));

      final uri = Uri.parse(ApiConstants.userAchievementsUrl(userId))
          .replace(queryParameters: {'page': '$page', 'per_page': '$perPage', 'sort': sort});
      final response = await http
          .get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        final list = data is Map ? data['items'] ?? data['data'] : data;
        return Right(Achievement.listFromJson(list is List ? list : const []));
      }
      return Left(ServerFailure(responseBody['message'] ?? 'Unknown error'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  Future<Either<Failure, List<TeamMembership>>> getUserTeams(
    int userId, {
    bool history = false,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('No authentication token found'));

      final url = history
          ? ApiConstants.userTeamsHistoryUrl(userId)
          : ApiConstants.userTeamsUrl(userId);
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        return Right(TeamMembership.listFromJson(data is List ? data : const []));
      }
      return Left(ServerFailure(responseBody['message'] ?? 'Unknown error'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  Future<Either<Failure, String>> logout() async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not logged in'));

      // §7 — unregister this device BEFORE the bearer token is discarded
      // below. `DELETE /devices` is scoped to the authenticated caller, so
      // doing it after the token is gone 401s and the device keeps receiving
      // pushes for an account that has logged out. This is the single logout
      // choke point, so ordering is guaranteed here regardless of caller.
      await di.sl<PushService>().unregisterToken();

      final response = await http.post(
        Uri.parse(ApiConstants.logoutUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        await PreferencesDatabase().removeValue('AUTH_TOKEN');
        await PreferencesDatabase().removeValue('user_id');
        return Right(body['message'] ?? 'Logged out successfully');
      } else {
        return Left(ServerFailure(body['message'] ?? 'Logout failed'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
