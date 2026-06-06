import '../../../../core/constants/debate_constants.dart';
import '../../../../core/mock/mock_data.dart';
import '../../domain/entities/debate.dart';
import '../../domain/entities/debate_results.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/score_entry.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/entities/statistics_models.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/debate_repositories.dart';

const _shortDelay = Duration(milliseconds: 400);
const _midDelay = Duration(milliseconds: 600);

class MockDebatesRepository implements DebatesRepository {
  @override
  Future<List<Debate>> fetchDebates() async {
    await Future.delayed(_midDelay);
    return mockDebates;
  }

  @override
  Future<Debate?> fetchDebate(String id) async {
    await Future.delayed(_shortDelay);
    return mockDebates.where((d) => d.id == id).cast<Debate?>().firstOrNull;
  }
}

class MockPreparationRoomRepository implements PreparationRoomRepository {
  @override
  Future<int> initialCountdownSeconds() async {
    await Future.delayed(_shortDelay);
    return kPrepRoomCountdownSeconds;
  }

  @override
  Future<List<PrepChatMessage>> fetchChat(String debateId) async {
    await Future.delayed(_shortDelay);
    return mockPrepChatFor(debateId);
  }

  @override
  Future<PrepChatMessage> sendMessage(String debateId, String text) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return PrepChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'd-001',
      authorName: 'أحمد الزهراني',
      text: text,
      createdAt: DateTime.now(),
      isMine: true,
    );
  }
}

class MockLiveSessionRepository implements LiveSessionRepository {
  List<LiveParticipant> _participants = mockLiveParticipants();
  List<POIRequest> _poiQueue = mockPOIRequests();

  @override
  Future<List<LiveParticipant>> fetchParticipants(String debateId) async {
    await Future.delayed(_midDelay);
    return List.of(_participants);
  }

  @override
  Future<List<POIRequest>> fetchPOIQueue() async {
    await Future.delayed(_shortDelay);
    return List.of(_poiQueue);
  }

  @override
  Future<List<PrivateNote>> fetchNotes() async {
    await Future.delayed(_shortDelay);
    return mockPrivateNotes();
  }

  @override
  Future<PrivateNote> sendNote({
    required String toName,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return PrivateNote(
      id: 'n-${DateTime.now().millisecondsSinceEpoch}',
      fromName: 'أحمد الزهراني',
      toName: toName,
      text: text,
      createdAt: DateTime.now(),
      fromMe: true,
    );
  }

  @override
  Future<POIRequest> sendPOIRequest(String debaterId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final req = POIRequest(
      id: 'poi-${DateTime.now().millisecondsSinceEpoch}',
      debaterId: debaterId,
      debaterName: _participants
              .where((p) => p.id == debaterId)
              .map((p) => p.name)
              .firstOrNull ??
          'مناظِر',
      team: TeamSide.government,
      createdAt: DateTime.now(),
    );
    _poiQueue = [..._poiQueue, req];
    return req;
  }

  @override
  Future<void> acceptPOI(String poiId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _poiQueue = _poiQueue.where((p) => p.id != poiId).toList();
  }

  @override
  Future<void> declinePOI(String poiId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _poiQueue = _poiQueue.where((p) => p.id != poiId).toList();
  }

  @override
  Future<void> toggleMute(String participantId, {required bool mute}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _participants = _participants
        .map((p) =>
            p.id == participantId ? p.copyWith(isMicOn: !mute) : p)
        .toList();
  }

  @override
  Future<void> toggleCamera(String participantId, {required bool enabled}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _participants = _participants
        .map((p) =>
            p.id == participantId ? p.copyWith(isCameraOn: enabled) : p)
        .toList();
  }

  @override
  Future<void> kickParticipant(String participantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _participants =
        _participants.where((p) => p.id != participantId).toList();
  }
}

class MockScoringRepository implements ScoringRepository {
  @override
  Future<List<ScoreEntry>> draftScoresFor(String debateId) async {
    await Future.delayed(_shortDelay);
    final debate =
        mockDebates.firstWhere((d) => d.id == debateId, orElse: () => mockDebates.first);
    final blanks = <ScoreEntry>[
      ...debate.governmentTeam.debaters.map((d) =>
          ScoreEntry(debaterId: d.id, debaterName: d.name, score: 70, comment: '')),
      ...debate.oppositionTeam.debaters.map((d) =>
          ScoreEntry(debaterId: d.id, debaterName: d.name, score: 70, comment: '')),
    ];
    return blanks;
  }

  @override
  Future<DebateResults> uploadFinalResults({
    required String debateId,
    required List<ScoreEntry> governmentScores,
    required List<ScoreEntry> oppositionScores,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final govTotal = governmentScores.fold<int>(0, (sum, s) => sum + s.score);
    final oppTotal = oppositionScores.fold<int>(0, (sum, s) => sum + s.score);
    return DebateResults(
      debateId: debateId,
      winningSide: govTotal >= oppTotal ? TeamSide.government : TeamSide.opposition,
      governmentTotal: govTotal,
      oppositionTotal: oppTotal,
      governmentScores: governmentScores,
      oppositionScores: oppositionScores,
    );
  }
}

class MockCoachRepository implements CoachRepository {
  List<JoinRequest> _joinRequests = mockJoinRequests();
  Team _team = mockTeamA;

  @override
  Future<Team> fetchTeam() async {
    await Future.delayed(_shortDelay);
    return _team;
  }

  @override
  Future<List<JoinRequest>> fetchJoinRequests() async {
    await Future.delayed(_shortDelay);
    return List.of(_joinRequests);
  }

  @override
  Future<void> acceptJoinRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _joinRequests = _joinRequests.where((r) => r.id != requestId).toList();
  }

  @override
  Future<void> declineJoinRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _joinRequests = _joinRequests.where((r) => r.id != requestId).toList();
  }

  @override
  Future<void> reorderPriorities(List<Debater> newOrder) async {
    await Future.delayed(const Duration(milliseconds: 250));
    assert(newOrder.length == kTeamSize,
        'Reordered list must contain exactly $kTeamSize debaters');
    final reprioritised = <Debater>[
      for (int i = 0; i < newOrder.length; i++)
        newOrder[i].copyWith(priority: i),
    ];
    _team = _team.copyWith(debaters: reprioritised);
  }

  @override
  Future<List<LiveParticipant>> fetchLiveParticipants(String debateId) async {
    await Future.delayed(_shortDelay);
    return mockLiveParticipants();
  }

  @override
  Future<List<ActivityEvent>> fetchActivityFeed(String debateId) async {
    await Future.delayed(_shortDelay);
    return mockActivityFeed();
  }

  @override
  Future<void> sendCoachNote({
    required String toDebaterName,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }
}

class MockStatisticsRepository implements StatisticsRepository {
  @override
  Future<GeneralStatistics> fetchGeneral() async {
    await Future.delayed(_midDelay);
    return mockGeneralStats;
  }

  @override
  Future<PersonalStatistics> fetchPersonal() async {
    await Future.delayed(_midDelay);
    return mockPersonalStats;
  }
}
