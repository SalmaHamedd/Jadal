import 'dart:convert';
import 'dart:io' show Platform;

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/services/token_storage.dart';

/// FCM device-token registry (§7.1).
///
/// `POST /devices` upserts keyed on the token — re-registering never
/// duplicates, and a token previously owned by another user is reassigned, so
/// pushes for user A can never land on a device now held by user B.
///
/// `DELETE /devices` is idempotent (200 even for an unknown token) and is
/// **scoped to the authenticated caller**, so it must be called BEFORE the auth
/// token is discarded on logout — an unauthenticated call 401s and the device
/// stays registered, still receiving pushes for an account that logged out.
class DeviceRepository {
  final http.Client _client;
  DeviceRepository({http.Client? client}) : _client = client ?? http.Client();

  /// `android` | `ios` — anything else is rejected by the backend with 422.
  static String get currentPlatform => Platform.isIOS ? 'ios' : 'android';

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Register or refresh this device's token.
  ///
  /// Called on successful login, on every FCM token rotation, and whenever the
  /// app language changes — the backend localises each push from the [locale]
  /// stored here, so a stale value means notifications in the wrong language.
  Future<Either<Failure, Unit>> registerDevice({
    required String token,
    required String locale,
  }) async {
    return _send(
      'register',
      (headers) => _client.post(
        Uri.parse(ApiConstants.devicesUrl),
        headers: headers,
        body: jsonEncode({
          'token': token,
          'platform': currentPlatform,
          'locale': locale,
        }),
      ),
    );
  }

  /// Unregister this device. Must run while still authenticated (see class doc).
  Future<Either<Failure, Unit>> unregisterDevice(String token) async {
    return _send(
      'unregister',
      (headers) => _client.delete(
        Uri.parse(ApiConstants.devicesUrl),
        headers: headers,
        body: jsonEncode({'token': token}),
      ),
    );
  }

  Future<Either<Failure, Unit>> _send(
    String label,
    Future<http.Response> Function(Map<String, String>) call,
  ) async {
    try {
      final res = await call(await _headers());
      final code = res.statusCode;
      if (code >= 200 && code < 300) return const Right(unit);

      String? message;
      if (res.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map) message = decoded['message']?.toString();
        } catch (_) {/* non-JSON error body */}
      }
      return switch (code) {
        401 => Left(AuthFailure(message ?? 'Unauthenticated')),
        422 => Left(ValidationFailure(message ?? 'Invalid device payload')),
        _ => Left(ServerFailure(message ?? 'Device $label failed ($code)')),
      };
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
