import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/services/token_storage.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';
import 'package:jadal_app/features/profile/data/models/profile_model.dart';

class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile() async {
    try {
      final token = await TokenStorage.getToken();
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
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return Left(AuthFailure('No authentication token found'));
      }

      final response = await http.put(
        Uri.parse(ApiConstants.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'phone': phone}),
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
      final token = await TokenStorage.getToken();
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
}
