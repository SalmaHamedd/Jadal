import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      return const Left(AuthFailure('Email and password are required'));
    }
    const user = User(
      id: 1,
      name: 'أحمد الزهراني',
      email: 'demo@jadal.app',
      role: 'debater',
      status: 'active',
      points: 1240,
      lang: 'ar',
      theme: 'dark',
    );
    await TokenStorage.saveRole(user.role);
    return const Right(user);
  }

  @override
  Future<Either<Failure, String>> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty) {
      return const Left(AuthFailure('Please enter your email'));
    }
    return const Right('Password reset link sent to your email');
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || token.isEmpty || password.isEmpty || passwordConfirmation.isEmpty) {
      return const Left(AuthFailure('All fields are required'));
    }
    if (password != passwordConfirmation) {
      return const Left(AuthFailure('Passwords do not match'));
    }
    return const Right('Password has been reset successfully');
  }
}