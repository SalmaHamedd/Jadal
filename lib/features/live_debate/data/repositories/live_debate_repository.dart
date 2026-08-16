import 'package:fpdart/fpdart.dart';

import '../../../../core/app_models/debate_format_model.dart';
import '../../../../core/app_models/framework.dart';
import '../../../../core/error/failures.dart';
import '../../domain/debate_registration.dart';
import '../../domain/debate_search_filter.dart';
import '../models/debate_list_model.dart';
import '../models/debate_result_model.dart';
import '../models/filter_options_model.dart';
import '../models/live_state_model.dart';
import '../models/registration_models.dart';
import '../models/room_token_model.dart';
import '../models/team_chat_history_model.dart';

/// REST surface for the backend live-debate mode. All calls send the
/// Sanctum bearer + `Accept: application/json` and return `Either<Failure, T>`.
abstract class LiveDebateRepository {
  /// `GET /debates?status=…&per_page=…&page=…` — one status per list tab.
  Future<Either<Failure, DebateListPage>> getDebates({
    required String status,
    int page = 1,
    int perPage = 15,
  });

  /// `GET /debates/{id}/live-state` — the full picture; fetch on screen entry
  /// and re-fetch on the room-availability events.
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

  /// `POST /debates/{id}/timer` `{action:"pause"|"resume"}` — chair:
  /// server-authoritative pause/resume; the server broadcasts `timer_update`.
  Future<Either<Failure, Unit>> setTimer({
    required int debateId,
    required String action,
  });

  /// `POST /debates/{id}/start-live` — chair: enter the live session
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

  /// `POST /debates/{id}/result/reveal` — chair reveals (confetti path).
  Future<Either<Failure, Unit>> revealResult(int debateId);

  /// `POST /debates/{id}/close-main` — chair closes the main room (auto-reveals).
  Future<Either<Failure, Unit>> closeMain(int debateId);

  /// `POST /debates/{id}/close-room` — chair force-closes the room: reveals a
  /// pending result or cancels the debate, broadcasts `room_closed`, then deletes
  /// the main LiveKit room. Returns the updated live-state.
  Future<Either<Failure, LiveStateModel>> closeRoom(int debateId);

  /// `POST /feedback` — `rating_debate` / `rating_judgement` (after reveal only).
  Future<Either<Failure, Unit>> sendFeedback({
    required int debateId,
    required String type,
    int? toUserId,
    required int rating,
    String? content,
  });

  // ── Registration ──────────────────────────────────────────────────────
  /// `POST /debates/{id}/register` — self-register as a team / solo debater /
  /// judge. Returns the backend's (bilingual) success message on 201.
  Future<Either<Failure, String>> register(DebateRegistration request);

  /// `GET /debates/{id}/registerable-teams`: the teams the caller may
  /// register for this debate (each with an eligibility flag).
  Future<Either<Failure, RegisterableTeams>> getRegisterableTeams(int debateId);

  /// `GET /debates/{id}/registrations`: who registered so far, split
  /// into teams / judges / solo (for the three registrant dialogs).
  Future<Either<Failure, DebateRegistrations>> getRegistrations(int debateId);

  // ── Persistent team chat ───────────────────────────────────────
  /// `GET /debates/{id}/chat` — the caller's own team chat history (team
  /// resolved server-side, never passed by the client).
  Future<Either<Failure, List<TeamChatHistoryMessage>>> getChatHistory(int debateId);

  /// `POST /debates/{id}/chat` `{message}` — persists a message. Fire this
  /// alongside the existing peer `team_chat` broadcast, not instead of it.
  Future<Either<Failure, TeamChatHistoryMessage>> sendChatMessage({
    required int debateId,
    required String message,
  });

  /// `POST /debates/{id}/chat/read` — marks every message in the caller's team
  /// chat as seen by them. No body.
  Future<Either<Failure, Unit>> markChatRead(int debateId);

  // ── Debate search + filter option lists ────────────────────────
  /// `GET /debates/search` — same paginated shape as [getDebates].
  Future<Either<Failure, DebateListPage>> searchDebates(
    DebateSearchFilter filter, {
    int page = 1,
    int perPage = 15,
  });

  /// `GET /motion-frameworks` — every framework defined in the system.
  Future<Either<Failure, List<Framework>>> getMotionFrameworks();

  /// `GET /debate-formats` — every structural debate format (WSDC/BP/etc).
  Future<Either<Failure, List<DebateFormatModel>>> getDebateFormats();

  /// `GET /debates/tags/distinct` — every distinct `debate.tag` value in use.
  Future<Either<Failure, List<String>>> getDebateTagsDistinct();

  /// `GET /judges` — active judges, name-sorted.
  Future<Either<Failure, List<JudgeOption>>> getJudgesList();

  /// `GET /teams/options` — light team list for filter dialogs (any auth user).
  Future<Either<Failure, List<TeamOption>>> getTeamsOptions({String? search});
}
