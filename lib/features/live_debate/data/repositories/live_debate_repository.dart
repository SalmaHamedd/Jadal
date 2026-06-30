import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/debate_registration.dart';
import '../models/debate_list_model.dart';
import '../models/debate_result_model.dart';
import '../models/live_state_model.dart';
import '../models/room_token_model.dart';

/// REST surface for the backend live-debate mode (§6/§7). All calls send the
/// Sanctum bearer + `Accept: application/json` and return `Either<Failure, T>`.
abstract class LiveDebateRepository {
  /// `GET /debates?status=…&per_page=…&page=…` — one status per list tab (§13).
  Future<Either<Failure, DebateListPage>> getDebates({
    required String status,
    int page = 1,
    int perPage = 15,
  });

  /// `GET /debates/{id}/live-state` — the full picture; fetch on screen entry
  /// and re-fetch on the room-availability events (§7).
  Future<Either<Failure, LiveStateModel>> getLiveState(int debateId);

  /// `GET /debates/{id}/token?room={main|prop|opp|result}` — fresh, room-scoped.
  Future<Either<Failure, RoomTokenModel>> getRoomToken(int debateId, String room);

  /// `POST /debates/{id}/team-speakers` — team leader picks the speaking order.
  /// [replySpeakerUserId] must be index 0 or 1 of [speakerUserIds] (reply formats).
  Future<Either<Failure, Unit>> setTeamSpeakers({
    required int debateId,
    required String side,
    required List<int> speakerUserIds,
    int? replySpeakerUserId,
  });

  /// `POST /debates/{id}/next-stage` — chair: stage 0→1 starts, past-last ends.
  Future<Either<Failure, Unit>> nextStage(int debateId);

  /// `POST /debates/{id}/rollback-to-lobby` — chair: back to stage 0.
  Future<Either<Failure, Unit>> rollbackToLobby(int debateId);

  /// `POST /debates/{id}/timer` `{action:"pause"|"resume"}` (V11 §0) — chair:
  /// server-authoritative pause/resume; the server broadcasts `timer_update`.
  Future<Either<Failure, Unit>> setTimer({
    required int debateId,
    required String action,
  });

  /// `POST /debates/{id}/start-live` (V11 §1) — chair: enter the live session
  /// from the lobby (intro phase); `current_stage` stays 0, broadcasts
  /// `debate_mode_started`.
  Future<Either<Failure, Unit>> startLive(int debateId);

  /// `POST /debates/{id}/stages/{phaseId}/poi` `{action:"raise"|"answer"}` (→204).
  Future<Either<Failure, Unit>> sendPoi({
    required int debateId,
    required int phaseId,
    required String action,
  });

  /// `POST /debates/{id}/result` — chair submits scores.
  Future<Either<Failure, Unit>> submitResult({
    required int debateId,
    required DebateResultModel result,
  });

  /// `POST /debates/{id}/result/reveal` — chair reveals (confetti path, §10).
  Future<Either<Failure, Unit>> revealResult(int debateId);

  /// `POST /debates/{id}/close-main` — chair closes the main room (auto-reveals).
  Future<Either<Failure, Unit>> closeMain(int debateId);

  /// `POST /debates/{id}/close-room` — chair force-closes the room: reveals a
  /// pending result or cancels the debate, broadcasts `room_closed`, then deletes
  /// the main LiveKit room (§FE-7). Returns the updated live-state.
  Future<Either<Failure, LiveStateModel>> closeRoom(int debateId);

  /// `POST /feedback` — `rating_debate` / `rating_judgement` (after reveal only).
  Future<Either<Failure, Unit>> sendFeedback({
    required int debateId,
    required String type,
    int? toUserId,
    required int rating,
    String? content,
  });

  // ── Registration (§15.1) ──────────────────────────────────────────────────────
  /// `POST /debates/{id}/register` — self-register as a team / solo debater /
  /// judge. Returns the backend's (bilingual) success message on 201.
  Future<Either<Failure, String>> register(DebateRegistration request);
}
