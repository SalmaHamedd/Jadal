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

/// 403 — not allowed for this role or room. Prefer hiding the control; if it
/// does surface, show a toast and leave the user where they are.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Forbidden']);
}

/// 404 — the record doesn't exist; pop back to the list.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

/// 410 — the resource was there but its access window has closed. Guests get
/// this when a share link is opened outside the debate's live window. It is not
/// an auth error, so never bounce to login on it.
class GoneFailure extends Failure {
  const GoneFailure([super.message = 'No longer available']);
}

/// 429 — throttled; show "try again in a minute".
class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'Too many requests']);
}
