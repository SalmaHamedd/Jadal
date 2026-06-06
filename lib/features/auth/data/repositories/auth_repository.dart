import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/services/token_storage.dart';
import 'package:jadal_app/features/auth/domain/entities/user.dart';
import 'package:jadal_app/features/auth/data/models/user_model.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/constants/api_constants.dart';

class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      final String message = responseBody['message'] ?? 'Unknown error';

      if (response.statusCode == 200 && responseBody['success'] == true) {
        final data = responseBody['data'];
        final String token = data['token'];
        await TokenStorage.saveToken(token); 
        final user = UserModel.fromJson(data['user']);
        return Right(user);
      }

      return Left(AuthFailure(message));
    } catch (e) {
      return Left(NetworkFailure('Network error'));
    }
  }

  Future<Either<Failure, String>> forgotPassword(String email) async {
    try {
      final response = await http.post(
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
    } catch (e) {
      return Left(NetworkFailure('Network error'));
    }
  }

  Future<Either<Failure, String>> resetPassword({
  required String email,
  required String token,
  required String password,
  required String passwordConfirmation,
}) async {
  try {
    final response = await http.post(
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
    } else {
      return Left(ServerFailure(message));
    }
  } catch (e) {
    return Left(NetworkFailure('Network error: $e'));
  }
}
}
