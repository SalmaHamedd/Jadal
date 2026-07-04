import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/preferences_database.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class ApiAuthRepository implements AuthRepository {
  final http.Client _client;

  ApiAuthRepository({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        final String token = data['token'];
        await PreferencesDatabase().setToken(token);
        await PreferencesDatabase().setValue('user_id', data['user']['id']);
        final user = UserModel.fromJson(data['user']);
        // Cache the account role for role-gated UI (registration options, etc.).
        await TokenStorage.saveRole(user.role);
        return Right(user);
      }

      return Left(AuthFailure(message));
    } catch (_) {
      return const Left(NetworkFailure('Network error'));
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Right(message);
      }

      return Left(AuthFailure(message));
    } catch (_) {
      return const Left(NetworkFailure('Network error'));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.resetPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && responseBody['success'] == true) {
        return Right(message);
      }

      return Left(AuthFailure(message));
    } catch (_) {
      return const Left(NetworkFailure('Network error'));
    }
  }
}