import '../../../../core/app_models/debate_format_model.dart';
import '../../../../core/app_models/motion.dart';
import '../../../../core/function/json_utils.dart';
import '../../domain/debate_room_role.dart';
import '../../domain/debate_status.dart';
import 'debate_result_model.dart';

/// Parsed `GET /debates/{id}/live-state` `data` object (§4) — the full picture
/// of a debate: rooms, judges, prop/opp speakers + roster, stages, motion,
/// format and (once revealed) the result.
class LiveStateModel {
  final DebateInfo debate;
  final DebateFormatModel format;

  /// `null` before the motion reveal time (show a placeholder, §F).
  final Motion? motion;
  final LiveRooms rooms;
  final List<JudgeEntry> judges;
  final SideInfo proposition;
  final SideInfo opposition;

  /// Speech list; the **last two can be reversed** (opp reply before prop) — read
  /// the order from here, never hard-code it (§F).
  final List<StageEntry> stages;

  /// `null` for non-judges until `result_revealed_at` is set (§F).
  final LiveResult? result;

  const LiveStateModel({
    required this.debate,
    required this.format,
    required this.motion,
    required this.rooms,
    required this.judges,
    required this.proposition,
    required this.opposition,
    required this.stages,
    required this.result,
  });

  factory LiveStateModel.fromJson(Map<String, dynamic> data) => LiveStateModel(
        debate: DebateInfo.fromJson(asMap(data['debate']) ?? const {}),
        format: DebateFormatModel.fromLiveState(asMap(data['format']) ?? const {}),
        motion: asMap(data['motion']) == null ? null : Motion.fromJson(asMap(data['motion'])!),
        rooms: LiveRooms.fromJson(asMap(data['rooms']) ?? const {}),
        judges: asMapList(data['judges']).map(JudgeEntry.fromJson).toList(),
        proposition: SideInfo.fromJson(asMap(data['proposition']) ?? const {}),
        opposition: SideInfo.fromJson(asMap(data['opposition']) ?? const {}),
        stages: asMapList(data['stages']).map(StageEntry.fromJson).toList(),
        result: asMap(data['result']) == null ? null : LiveResult.fromJson(asMap(data['result'])!),
      );

  /// The chair judge (`is_chair == true`), if present.
  JudgeEntry? get chairJudge {
    for (final j in judges) {
      if (j.isChair) return j;
    }
    return null;
  }

  /// Resolve the current user's involvement by matching their auth id against
  /// judges / speakers / team members (§4).
  bool isJudge(int userId) => judges.any((j) => j.user.id == userId);
  bool isChair(int userId) => chairJudge?.user.id == userId;

  SpeakerEntry? speakerByUserId(int userId) {
    for (final s in [...proposition.speakers, ...opposition.speakers]) {
      if (s.user.id == userId) return s;
    }
    return null;
  }

  /// The speaker whose participant row id matches `stages[].participant_id`
  /// (used to attribute a completed stage's score to a speaker/side, §10).
  SpeakerEntry? speakerByParticipantId(int? participantId) {
    if (participantId == null) return null;
    for (final s in [...proposition.speakers, ...opposition.speakers]) {
      if (s.id == participantId) return s;
    }
    return null;
  }

  /// 'proposition' | 'opposition' | null for the given user, if they're a speaker.
  String? sideForUser(int userId) => speakerByUserId(userId)?.side;
}

/// `live-state.debate`.
class DebateInfo {
  final int id;
  final String title;
  final String? tag;
  final DebateStatus status;
  final String? statusRaw;
  final int currentStage;

  /// Server timestamp the in-progress speaking phase started at (B3) — `null` in
  /// the lobby / stage 0. Used to seed the timer so it reads 0 before any speech
  /// and syncs a mid-speech (re)join to the real elapsed time.
  final DateTime? currentStageStartedAt;

  /// FE-3 (B1): set when the speeches finish → the result phase opens while the
  /// debate is STILL `live`. Gate the result UI on this (or `rooms.result.open`),
  /// NEVER on `status == completed`.
  final DateTime? speechesCompletedAt;
  final String? cancellationReason;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? motionRevealedAt;
  final DateTime? prepRoomsOpenedAt;
  final DateTime? resultRevealedAt;

  const DebateInfo({
    required this.id,
    required this.title,
    required this.tag,
    required this.status,
    required this.statusRaw,
    required this.currentStage,
    required this.currentStageStartedAt,
    required this.speechesCompletedAt,
    required this.cancellationReason,
    required this.scheduledAt,
    required this.startedAt,
    required this.endedAt,
    required this.motionRevealedAt,
    required this.prepRoomsOpenedAt,
    required this.resultRevealedAt,
  });

  factory DebateInfo.fromJson(Map<String, dynamic> j) => DebateInfo(
        id: asInt(j['id']) ?? 0,
        title: asString(j['title']) ?? '',
        tag: asString(j['tag']),
        status: DebateStatus.fromWire(asString(j['status'])),
        statusRaw: asString(j['status']),
        currentStage: asInt(j['current_stage']) ?? 0,
        currentStageStartedAt: asDate(j['current_stage_started_at']),
        speechesCompletedAt: asDate(j['speeches_completed_at']),
        cancellationReason: asString(j['cancellation_reason']),
        scheduledAt: asDate(j['scheduled_at']),
        startedAt: asDate(j['started_at']),
        endedAt: asDate(j['ended_at']),
        motionRevealedAt: asDate(j['motion_revealed_at']),
        prepRoomsOpenedAt: asDate(j['prep_rooms_opened_at']),
        resultRevealedAt: asDate(j['result_revealed_at']),
      );

  bool get isCancelled => status == DebateStatus.cancelled;
  bool get isCompleted => status == DebateStatus.completed;
  bool get resultRevealed => resultRevealedAt != null;

  /// FE-3: speeches are done (result phase open) while still `live`.
  bool get speechesCompleted => speechesCompletedAt != null;
}

/// `live-state.rooms` — the four rooms with pre-join gating.
class LiveRooms {
  final RoomEntry main;
  final RoomEntry prop;
  final RoomEntry opp;
  final RoomEntry result;

  const LiveRooms({
    required this.main,
    required this.prop,
    required this.opp,
    required this.result,
  });

  factory LiveRooms.fromJson(Map<String, dynamic> j) => LiveRooms(
        main: RoomEntry.fromJson(asMap(j['main']) ?? const {}),
        prop: RoomEntry.fromJson(asMap(j['prop']) ?? const {}),
        opp: RoomEntry.fromJson(asMap(j['opp']) ?? const {}),
        result: RoomEntry.fromJson(asMap(j['result']) ?? const {}),
      );
}

class RoomEntry {
  final String? name;
  final bool open;
  final bool joinableForMe;
  final DebateRoomRole? roleIfJoined;

  const RoomEntry({
    required this.name,
    required this.open,
    required this.joinableForMe,
    required this.roleIfJoined,
  });

  factory RoomEntry.fromJson(Map<String, dynamic> j) => RoomEntry(
        name: asString(j['name']),
        open: asBool(j['open']),
        joinableForMe: asBool(j['joinable_for_me']),
        roleIfJoined: j['role_if_joined'] == null
            ? null
            : DebateRoomRole.fromWire(asString(j['role_if_joined'])),
      );
}

/// A user inside live-state. Captures both the minimal judge/member shape and
/// the full speaker `user` shape (extra fields are simply absent → null).
class LiveUser {
  final int id;
  final String name;
  final String? role;
  final String? status;
  final String? avatarUrl; // sanitised — malformed double-URLs become null (§4)
  final String? email;
  final String? phone;
  final int points;
  final DateTime? createdAt;

  const LiveUser({
    required this.id,
    required this.name,
    this.role,
    this.status,
    this.avatarUrl,
    this.email,
    this.phone,
    this.points = 0,
    this.createdAt,
  });

  factory LiveUser.fromJson(Map<String, dynamic> j) => LiveUser(
        id: asInt(j['id']) ?? 0,
        name: asString(j['name']) ?? '',
        role: asString(j['role']),
        status: asString(j['status']),
        avatarUrl: sanitizeAvatarUrl(asString(j['avatar_url'])),
        email: asString(j['email']),
        phone: asString(j['phone']),
        points: asInt(j['points']) ?? 0,
        createdAt: asDate(j['created_at']),
      );
}

/// Some `avatar_url`s come back malformed as `/storage/https://…` (a doubled
/// URL). Treat those as absent so the UI falls back to the initials avatar (§4).
String? sanitizeAvatarUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  if (raw.startsWith('/storage/http')) return null;
  return raw;
}

/// One slot in `speaking_order[]` (B4) — `{phase_order, user_id, participant_id}`.
/// DUPLICATES ARE ALLOWED (a 2-person team can fill 3 slots as `[A, B, A]`).
class SpeakingOrderEntry {
  final int phaseOrder;
  final int userId;
  final int? participantId;

  const SpeakingOrderEntry({
    required this.phaseOrder,
    required this.userId,
    required this.participantId,
  });

  factory SpeakingOrderEntry.fromJson(Map<String, dynamic> j) => SpeakingOrderEntry(
        phaseOrder: asInt(j['phase_order']) ?? 0,
        userId: asInt(j['user_id']) ?? 0,
        participantId: asInt(j['participant_id']),
      );
}

/// `live-state.proposition` / `.opposition`.
class SideInfo {
  final BackendTeam? team;
  final bool isRandom;
  final List<LiveUser> members; // wider roster
  final List<SpeakerEntry> speakers; // approved debaters on this side

  /// B4: the N-slot speaking order with DUPLICATES allowed (multi-role). Drives
  /// the fixed N equal slots (FE-7) and the order dialog (FE-8).
  final List<SpeakingOrderEntry> speakingOrder;

  const SideInfo({
    required this.team,
    required this.isRandom,
    required this.members,
    required this.speakers,
    required this.speakingOrder,
  });

  factory SideInfo.fromJson(Map<String, dynamic> j) => SideInfo(
        team: asMap(j['team']) == null ? null : BackendTeam.fromJson(asMap(j['team'])!),
        isRandom: asBool(j['is_random']),
        members: asMapList(j['members']).map(LiveUser.fromJson).toList(),
        speakers: asMapList(j['speakers']).map(SpeakerEntry.fromJson).toList(),
        speakingOrder: (asMapList(j['speaking_order']).map(SpeakingOrderEntry.fromJson).toList()
              ..sort((a, b) => a.phaseOrder.compareTo(b.phaseOrder))),
      );

  /// The speaking-order user ids in phase order (duplicates preserved). Empty
  /// when the backend hasn't sent `speaking_order` yet.
  List<int> get speakingOrderUserIds => speakingOrder.map((e) => e.userId).toList();

  /// Speakers ordered by `speaking_phase_order` (1-based), nulls last.
  List<SpeakerEntry> get orderedSpeakers {
    final list = [...speakers];
    list.sort((a, b) =>
        (a.speakingPhaseOrder ?? 1 << 30).compareTo(b.speakingPhaseOrder ?? 1 << 30));
    return list;
  }

  SpeakerEntry? get replySpeaker {
    for (final s in speakers) {
      if (s.isReplySpeaker) return s;
    }
    return null;
  }
}

class BackendTeam {
  final int id;
  final String name;
  final String? status;
  final bool isRandom;
  final int membersCount;
  final List<TeamMemberRef> members;

  const BackendTeam({
    required this.id,
    required this.name,
    required this.status,
    required this.isRandom,
    required this.membersCount,
    required this.members,
  });

  factory BackendTeam.fromJson(Map<String, dynamic> j) => BackendTeam(
        id: asInt(j['id']) ?? 0,
        name: asString(j['name']) ?? '',
        status: asString(j['status']),
        isRandom: asBool(j['is_random']),
        membersCount: asInt(j['members_count']) ?? 0,
        members: asMapList(j['members']).map(TeamMemberRef.fromJson).toList(),
      );
}

class TeamMemberRef {
  final int id;
  final int userId;
  final int? priority;
  final String? status;
  final DateTime? joinedAt;

  const TeamMemberRef({
    required this.id,
    required this.userId,
    required this.priority,
    required this.status,
    required this.joinedAt,
  });

  factory TeamMemberRef.fromJson(Map<String, dynamic> j) => TeamMemberRef(
        id: asInt(j['id']) ?? 0,
        userId: asInt(j['user_id']) ?? 0,
        priority: asInt(j['priority']),
        status: asString(j['status']),
        joinedAt: asDate(j['joined_at']),
      );
}

class SpeakerEntry {
  final int id;
  final LiveUser user;
  final int? teamId;
  final String? role;
  final String? side; // 'proposition' | 'opposition'
  final String? status;
  final bool isChair;
  final bool isAttended;
  final int? speakingPhaseOrder;

  /// G3: the backend's authoritative reply-speaker flag (`is_reply_speaker`).
  /// This — NOT the role string — drives the PR/OR label and pre-selecting the
  /// reply speaker in the order dialog.
  final bool isReplySpeakerFlag;

  const SpeakerEntry({
    required this.id,
    required this.user,
    required this.teamId,
    required this.role,
    required this.side,
    required this.status,
    required this.isChair,
    required this.isAttended,
    required this.speakingPhaseOrder,
    required this.isReplySpeakerFlag,
  });

  factory SpeakerEntry.fromJson(Map<String, dynamic> j) => SpeakerEntry(
        id: asInt(j['id']) ?? 0,
        user: LiveUser.fromJson(asMap(j['user']) ?? const {}),
        teamId: asInt(j['team_id']),
        role: asString(j['role']),
        side: asString(j['side']),
        status: asString(j['status']),
        isChair: asBool(j['is_chair']),
        isAttended: asBool(j['is_attended']),
        speakingPhaseOrder: asInt(j['speaking_phase_order']),
        isReplySpeakerFlag: asBool(j['is_reply_speaker']),
      );

  /// G3: read the boolean `is_reply_speaker` (now present, V5 §2). The old
  /// `role.contains('reply')` heuristic was always false (role is just
  /// "debater") — kept only as a defensive fallback.
  bool get isReplySpeaker =>
      isReplySpeakerFlag || (role ?? '').toLowerCase().contains('reply');
}

/// `live-state.stages[]` — one speech phase.
class StageEntry {
  /// 1-based phase order (matches `stage_changed.current_stage` + `stage_scores.stage_order`).
  final int orderIndex;
  final String name;
  final String? role;
  final bool isReply;
  final int? durationSeconds;
  final String status;

  /// The participant assigned to this stage; maps to `speakers[].id`.
  /// Can be `null` (e.g. completed/seeded debates — see open Q8).
  final int? participantId;

  /// The user id of this stage's speaker, resolved server-side (B3) — saves us
  /// mapping `participant_id → user`. `null` for stages with no speaker.
  final int? speakerUserId;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int poiRaisedCount;
  final int poiAnsweredCount;
  final String? audioUrl;
  final String? speechText;

  /// The DB phase id needed by `POST /stages/{phaseId}/poi`. The live-state
  /// sample omits it (only `order_index`); parsed when present (open Q7).
  final int? id;

  const StageEntry({
    required this.orderIndex,
    required this.name,
    required this.role,
    required this.isReply,
    required this.durationSeconds,
    required this.status,
    required this.participantId,
    required this.speakerUserId,
    required this.startedAt,
    required this.endedAt,
    required this.poiRaisedCount,
    required this.poiAnsweredCount,
    required this.audioUrl,
    required this.speechText,
    required this.id,
  });

  factory StageEntry.fromJson(Map<String, dynamic> j) => StageEntry(
        orderIndex: asInt(j['order_index']) ?? 0,
        name: asString(j['name']) ?? '',
        role: asString(j['role']),
        isReply: asBool(j['is_reply']),
        durationSeconds: asInt(j['duration_seconds']),
        status: asString(j['status']) ?? 'pending',
        participantId: asInt(j['participant_id']),
        speakerUserId: asInt(j['speaker_user_id']),
        startedAt: asDate(j['started_at']),
        endedAt: asDate(j['ended_at']),
        poiRaisedCount: asInt(j['poi_raised_count']) ?? 0,
        poiAnsweredCount: asInt(j['poi_answered_count']) ?? 0,
        audioUrl: asString(j['audio_url']),
        speechText: asString(j['speech_text']),
        id: asInt(j['id']),
      );
}

class JudgeEntry {
  final int id;
  final LiveUser user;
  final int? judgeOrder;
  final bool isChair;
  final bool isAttended;

  const JudgeEntry({
    required this.id,
    required this.user,
    required this.judgeOrder,
    required this.isChair,
    required this.isAttended,
  });

  factory JudgeEntry.fromJson(Map<String, dynamic> j) => JudgeEntry(
        id: asInt(j['id']) ?? 0,
        user: LiveUser.fromJson(asMap(j['user']) ?? const {}),
        judgeOrder: asInt(j['judge_order']),
        isChair: asBool(j['is_chair']),
        isAttended: asBool(j['is_attended']),
      );
}
