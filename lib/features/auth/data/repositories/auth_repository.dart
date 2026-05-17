import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final bool success = responseBody['success'] ?? false;

        if (success) {
          final Map<String, dynamic> data = responseBody['data'];
          final String token = data['token']; // you can store this later
          final Map<String, dynamic> userJson = data['user'];
          final user = UserModel.fromJson(userJson);
          return Right(user);
        } else {
          final String message = responseBody['message'] ?? 'Login failed';
          return Left(AuthFailure(message));
        }
      } else if (response.statusCode == 401) {
        return Left(AuthFailure('Invalid email or password'));
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Check your internet connection: $e'));
    }
  }
}