import '../../../../core/app_models/framework.dart';
import '../../../../core/app_models/motion.dart';
import '../../domain/live_debate_data.dart';
import '../models/debate_models.dart';

/// In-memory mock for the live-debate feature (§5).
///
/// Returns 4 rooms, two named teams, a judges list, a motion (categories +
/// tags), an audience list and a [DebateFormat]. Implements [LiveDebateData] so
/// the shared widget set renders it exactly like the backend-derived source.
class MockLiveDebateData implements LiveDebateData {
  const MockLiveDebateData();

  /// Used so access rules (§8.1) can be evaluated against the local user.
  ///
  /// NOTE: For solo socket testing (§9) the local participant is treated as the
  /// first proposition speaker regardless of this id. Change this to a judge id
  /// (e.g. 'judge_1') or an opposition debater id to exercise other gating.
  @override
  String get currentUserId => 'prop_1';

  @override
  DebateFormat get format => const DebateFormat(
        preparationPeriod: Duration(minutes: 30),
        speechDuration: Duration(minutes: 8),
        protectedPeriod: Duration(minutes: 1),
        extraTime: Duration(seconds: 30),
        replySpeech: true,
        replyDuration: Duration(minutes: 4),
      );

  /// The debate start time. Prep rooms are open while `now` is within
  /// [DebateFormat.preparationPeriod] of this instant.
  @override
  DateTime get debateStartTime =>
      DateTime.now().subtract(const Duration(minutes: 2));

  @override
  TeamInfo get propositionTeam => const TeamInfo(
        teamId: 'team_falcons',
        teamName: 'Falcons',
        side: DebateSide.proposition,
        debaters: [
          Debater(id: 'prop_1', name: 'Ahmad Al-Sayed', ranking: 3),
          Debater(id: 'prop_2', name: 'Lina Hassan', ranking: 2),
          Debater(id: 'prop_3', name: 'Omar Khalil', ranking: 1),
        ],
      );

  @override
  TeamInfo get oppositionTeam => const TeamInfo(
        teamId: 'team_owls',
        teamName: 'Owls',
        side: DebateSide.opposition,
        debaters: [
          Debater(id: 'opp_1', name: 'Sara Mansour', ranking: 3),
          Debater(id: 'opp_2', name: 'Yousef Nabil', ranking: 2),
          Debater(id: 'opp_3', name: 'Mariam Adel', ranking: 1),
        ],
      );

  @override
  List<JudgeInfo> get judges => const [
        JudgeInfo(id: 'judge_1', name: 'Dr. Faisal Noor'),
        JudgeInfo(id: 'judge_2', name: 'Huda Karim'),
        JudgeInfo(id: 'judge_3', name: 'Tariq Saleh'),
      ];

  @override
  Motion get motion => const Motion(
        id: 1,
        text:
            'This House believes that developing nations should prioritise '
            'renewable energy over rapid industrialisation.',
        tags: ['Policy', 'Sustainability'],
        frameworks: [
          Framework(id: 1, name: 'Environment', colorHex: '#2E9E5B'),
          Framework(id: 2, name: 'Economics', colorHex: '#8B5CF6'),
          Framework(id: 3, name: 'Development', colorHex: '#F59E0B'),
        ],
      );

  @override
  List<AudienceMember> get audience => const [
        AudienceMember(id: 'aud_1', name: 'Nour Saad', role: 'Spectator'),
        AudienceMember(id: 'aud_2', name: 'Khaled Amir', role: 'Coach'),
        AudienceMember(id: 'aud_3', name: 'Reem Fadel', role: 'Spectator'),
        AudienceMember(id: 'aud_4', name: 'Salma Adib', role: 'Press'),
        AudienceMember(id: 'aud_5', name: 'Bilal Hadi', role: 'Spectator'),
        AudienceMember(id: 'aud_6', name: 'Dana Rashid', role: 'Observer'),
      ];

  @override
  List<String> get judgeIds => judges.map((j) => j.id).toList();

  /// The 4 lobby rooms (§8.1). Display names are placeholders; the lobby
  /// localises them and appends team names in parentheses.
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
