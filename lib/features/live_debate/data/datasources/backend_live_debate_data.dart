import '../../../../core/app_models/debate_format_model.dart';
import '../../../../core/app_models/motion.dart';
import '../../../../core/function/media_url.dart';
import '../../domain/live_debate_data.dart';
import '../models/debate_models.dart';
import '../models/live_state_model.dart';

class BackendLiveDebateData implements LiveDebateData {
  final LiveStateModel state;
  final int myUserId;

  const BackendLiveDebateData(this.state, this.myUserId);

  /// An empty placeholder used before `live-state` has loaded.
  factory BackendLiveDebateData.empty() =>
      BackendLiveDebateData(LiveStateModel.fromJson(const {}), 0);

  @override
  String get currentUserId => myUserId.toString();

  @override
  DebateFormat get format {
    final f = state.format;
    final speech = f.speechTimeSeconds ??
        (state.stages.isNotEmpty ? state.stages.first.durationSeconds : null) ??
        420;
    // The protected window is configured per format. `0` is a real value
    // ("POIs open throughout"), so only a null falls back to the old default.
    final protected = f.protectedTimeSeconds;
    return DebateFormat(
      preparationPeriod:
          DebateFormatModel.hoursOffsetToDuration(f.prepRoomsOpenOffsetHours ?? 1),
      speechDuration: Duration(seconds: speech),
      protectedPeriod: Duration(seconds: protected ?? 60),
      // Grace time is not configurable yet, so this stays a fixed nominal value.
      extraTime: const Duration(seconds: 30),
      replySpeech: f.hasReply,
      replyDuration: Duration(seconds: f.replyTimeSeconds ?? 240),
      poiOffset: protected == null ? null : Duration(seconds: protected),
    );
  }

  @override
  DateTime get debateStartTime =>
      state.debate.startedAt ?? state.debate.scheduledAt ?? DateTime.now();

  @override
  TeamInfo get propositionTeam => _team(state.proposition, DebateSide.proposition);

  @override
  TeamInfo get oppositionTeam => _team(state.opposition, DebateSide.opposition);

  /// The number of fixed speaking slots per side (= `speakers_per_side`),
  /// so both team columns render the SAME count (a 2-person side no longer
  /// stretches its cards to a 3-person side's height — the shorter side just
  /// leaves its bottom slot(s) empty). Falls back to the larger side's roster so
  /// the columns still match when the format omits the count.
  int get slotsPerSide {
    final fmt = state.format.speakersPerSide;
    if (fmt != null && fmt > 0) return fmt;
    final p = propositionTeam.debaters.length;
    final o = oppositionTeam.debaters.length;
    final m = p >= o ? p : o;
    return m > 0 ? m : 1;
  }

  TeamInfo _team(SideInfo side, DebateSide s) {
    // Distinct roster (one entry per speaker), phase-order sorted. The fixed
    // N-slot rendering is applied at the widget layer off [slotsPerSide];
    // this stays the canonical roster used by the prep/lobby grids + the order
    // dialog's dropdown, so those are unaffected.
    final ordered = side.orderedSpeakers;
    final debaters = <Debater>[
      for (var i = 0; i < ordered.length; i++)
        Debater(
          id: ordered[i].user.id.toString(),
          name: ordered[i].user.name,
          // Higher rank = earlier speaker (only used by the test leader rule).
          ranking: ordered.length - i,
          avatarUrl: resolveMediaUrl(ordered[i].user.avatarUrl),
        ),
    ];
    return TeamInfo(
      teamId: (side.team?.id ?? (s == DebateSide.proposition ? -1 : -2)).toString(),
      teamName: side.team?.name ??
          (s == DebateSide.proposition ? 'Proposition' : 'Opposition'),
      side: s,
      debaters: debaters,
    );
  }

  @override
  List<JudgeInfo> get judges => state.judges
      .map((j) => JudgeInfo(
            id: j.user.id.toString(),
            name: j.user.name,
            avatarUrl: resolveMediaUrl(j.user.avatarUrl),
          ))
      .toList();

  @override
  List<String> get judgeIds => judges.map((j) => j.id).toList();

  @override
  Motion get motion => state.motion ?? const Motion(text: '');

  @override
  List<AudienceMember> get audience {
    // live-state has no explicit audience list; surface roster members who
    // aren't speakers as spectators (trainers/viewers aren't enumerated).
    final speakerUserIds = <int>{
      ...state.proposition.speakers.map((s) => s.user.id),
      ...state.opposition.speakers.map((s) => s.user.id),
    };
    final out = <AudienceMember>[];
    for (final m in [...state.proposition.members, ...state.opposition.members]) {
      if (!speakerUserIds.contains(m.id)) {
        out.add(AudienceMember(
          id: m.id.toString(),
          name: m.name,
          role: m.role ?? 'Member',
          avatarUrl: resolveMediaUrl(m.avatarUrl),
        ));
      }
    }
    return out;
  }

  @override
  List<DebateRoom> get rooms => [
        DebateRoom(
          type: DebateRoomType.proposition,
          displayName: 'Proposition',
          team: propositionTeam,
        ),
        DebateRoom(
          type: DebateRoomType.opposition,
          displayName: 'Opposition',
          team: oppositionTeam,
        ),
        DebateRoom(
          type: DebateRoomType.liveDebate,
          displayName: 'Live Debate',
          judgeIds: judgeIds,
          propTeamId: propositionTeam.teamId,
          oppTeamId: oppositionTeam.teamId,
        ),
        DebateRoom(
          type: DebateRoomType.result,
          displayName: 'Result',
          judgeIds: judgeIds,
        ),
      ];

  @override
  TeamInfo? teamById(String? teamId) {
    if (teamId == propositionTeam.teamId) return propositionTeam;
    if (teamId == oppositionTeam.teamId) return oppositionTeam;
    return null;
  }
}
