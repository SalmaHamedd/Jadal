import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/function/json_utils.dart';
import '../../../../core/services/token_storage.dart';
import '../../domain/debate_registration.dart';
import '../models/debate_list_model.dart';
import '../models/debate_result_model.dart';
import '../models/live_state_model.dart';
import '../models/room_token_model.dart';
import 'live_debate_repository.dart';

/// HTTP implementation of [LiveDebateRepository] (matches the app's
/// repository-pattern convention: `http.Client` + `TokenStorage` bearer +
/// `Accept: application/json` + `Either<Failure, T>`). Error mapping follows
/// docs §G.
class LiveDebateRepositoryImpl implements LiveDebateRepository {
  final http.Client _client;

  LiveDebateRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await TokenStorage.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json', // mandatory (§0)
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Runs [run], catching network errors, then maps the response to the decoded
  /// envelope body (`{success,message,data,…}`) or a [Failure].
  Future<Either<Failure, Map<String, dynamic>?>> _safe(
      Future<http.Response> Function() run) async {
    try {
      return await _handle(await run());
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>?>> _handle(http.Response res) async {
    final code = res.statusCode;
    Map<String, dynamic>? body;
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {/* non-JSON body (e.g. 204) */}
    }

    if (code >= 200 && code < 300) return Right(body);

    final message = asString(body?['message']);
    switch (code) {
      case 401:
        await TokenStorage.deleteToken(); // bounce to login + clear token (§G)
        return Left(AuthFailure(message ?? 'Unauthenticated'));
      case 403:
        return Left(ForbiddenFailure(message ?? 'Forbidden'));
      case 404:
        return Left(NotFoundFailure(message ?? 'Not found'));
      case 422:
        return Left(ValidationFailure(message ?? 'Validation error',
            errors: _parseErrors(body)));
      case 429:
        return Left(RateLimitFailure(message ?? 'Too many requests'));
      default:
        return Left(ServerFailure(message ?? 'Server error ($code)'));
    }
  }

  Map<String, List<String>>? _parseErrors(Map<String, dynamic>? body) {
    final raw = body?['errors'];
    if (raw is! Map) return null;
    final out = <String, List<String>>{};
    raw.forEach((k, v) {
      out['$k'] = v is List ? v.map((e) => e.toString()).toList() : [v.toString()];
    });
    return out;
  }

  /// Maps a successful envelope's `data` object into a model.
  Either<Failure, T> _model<T>(
    Either<Failure, Map<String, dynamic>?> res,
    T Function(Map<String, dynamic> data) build,
  ) =>
      res.flatMap((body) {
        final data = asMap(body?['data']);
        if (data == null) return const Left(ServerFailure('Unexpected empty response'));
        return Right(build(data));
      });

  Either<Failure, Unit> _unit(Either<Failure, Map<String, dynamic>?> res) =>
      res.map((_) => unit);

  // ── Endpoints ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, DebateListPage>> getDebates({
    required String status,
    int page = 1,
    int perPage = 15,
  }) async {
    final uri = Uri.parse(ApiConstants.debatesUrl).replace(queryParameters: {
      'status': status,
      'per_page': perPage.toString(),
      'page': page.toString(),
    });
    final res = await _safe(() async => _client.get(uri, headers: await _headers(json: false)));
    return res.flatMap((body) {
      if (body == null) return const Left(ServerFailure('Unexpected empty response'));
      return Right(DebateListPage.fromEnvelope(body));
    });
  }

  @override
  Future<Either<Failure, LiveStateModel>> getLiveState(int debateId) async {
    final res = await _safe(() async => _client.get(
          Uri.parse(ApiConstants.liveStateUrl(debateId)),
          headers: await _headers(json: false),
        ));
    return _model(res, LiveStateModel.fromJson);
  }

  @override
  Future<Either<Failure, RoomTokenModel>> getRoomToken(int debateId, String room) async {
    final uri = Uri.parse(ApiConstants.tokenUrl(debateId)).replace(queryParameters: {'room': room});
    final res = await _safe(() async => _client.get(uri, headers: await _headers(json: false)));
    return _model(res, RoomTokenModel.fromJson);
  }

  @override
  Future<Either<Failure, Unit>> setTeamSpeakers({
    required int debateId,
    required String side,
    required List<int> speakerUserIds,
    int? replySpeakerUserId,
  }) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.teamSpeakersUrl(debateId)),
          headers: await _headers(),
          body: jsonEncode({
            'side': side,
            'speaker_user_ids': speakerUserIds,
            'reply_speaker_user_id': ?replySpeakerUserId,
          }),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, Unit>> nextStage(int debateId) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.nextStageUrl(debateId)),
          headers: await _headers(),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, Unit>> rollbackToLobby(int debateId) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.rollbackToLobbyUrl(debateId)),
          headers: await _headers(),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, Unit>> sendPoi({
    required int debateId,
    required int phaseId,
    required String action,
  }) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.poiUrl(debateId, phaseId)),
          headers: await _headers(),
          body: jsonEncode({'action': action}),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, Unit>> submitResult({
    required int debateId,
    required DebateResultModel result,
  }) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.resultUrl(debateId)),
          headers: await _headers(),
          body: jsonEncode(result.toJson()),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, Unit>> revealResult(int debateId) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.revealResultUrl(debateId)),
          headers: await _headers(),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, Unit>> closeMain(int debateId) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.closeMainUrl(debateId)),
          headers: await _headers(),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, LiveStateModel>> closeRoom(int debateId) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.closeRoomUrl(debateId)),
          headers: await _headers(),
        ));
    // Returns the full LiveStateResource reflecting the post-close state.
    return _model(res, LiveStateModel.fromJson);
  }

  @override
  Future<Either<Failure, Unit>> sendFeedback({
    required int debateId,
    required String type,
    int? toUserId,
    required int rating,
    String? content,
  }) async {
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.feedbackUrl),
          headers: await _headers(),
          body: jsonEncode({
            'debate_id': debateId,
            'type': type,
            'to_user_id': ?toUserId,
            'scores': {'rating': rating},
            'content': ?content,
          }),
        ));
    return _unit(res);
  }

  @override
  Future<Either<Failure, String>> register(DebateRegistration request) async {
    final body = <String, dynamic>{
      'as': request.kind.wire,
      if (request.kind == RegistrationKind.team) 'team_id': request.teamId,
    };
    final res = await _safe(() async => _client.post(
          Uri.parse(ApiConstants.registerUrl(request.debateId)),
          headers: await _headers(),
          body: jsonEncode(body),
        ));
    // Surface the backend's bilingual success message ("…| Registered…").
    return res.map((b) => asString(b?['message']) ?? 'Registered successfully.');
  }
}
