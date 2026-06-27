import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure([this.message = '']);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error']);
}

class OfflineFailure extends Failure {
  const OfflineFailure([super.message = 'No internet connection']);
}

class EmptyCacheFailure extends Failure {
  const EmptyCacheFailure([super.message = 'No cached data']);
}

class ValidationFailure extends Failure {
  /// Per-field validation errors from a 422 response's `errors` map.
  final Map<String, List<String>>? errors;
  const ValidationFailure(super.message, {this.errors});

  @override
  List<Object?> get props => [message, errors];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// 403 — the action isn't allowed for this role/room. Prefer hiding the control;
/// if surfaced, show a non-blocking toast and keep the user where they are (§G).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Forbidden']);
}

/// 404 — the debate/phase/participant doesn't exist; pop back to the list (§G).
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

/// 429 — throttled; show "try again in a minute" (§G).
class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'Too many requests']);
}
