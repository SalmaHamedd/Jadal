import '../entities/debate.dart';
import '../entities/debater.dart';
import '../entities/debate_results.dart';
import '../entities/score_entry.dart';
import '../entities/session_models.dart';
import '../entities/statistics_models.dart';
import '../entities/team.dart';

/// Read/refresh debate listings + detail lookups.
abstract class DebatesRepository {
  Future<List<Debate>> fetchDebates();
  Future<Debate?> fetchDebate(String id);
}

/// Preparation room: countdown source, chat backlog + outgoing messages.
abstract class PreparationRoomRepository {
  /// Returns the seconds remaining at fetch time.
  Future<int> initialCountdownSeconds();
  Future<List<PrepChatMessage>> fetchChat(String debateId);
  Future<PrepChatMessage> sendMessage(String debateId, String text);
}

/// Live session interactions for debaters and judges.
abstract class LiveSessionRepository {
  Future<List<LiveParticipant>> fetchParticipants(String debateId);
  Future<List<POIRequest>> fetchPOIQueue();
  Future<List<PrivateNote>> fetchNotes();
  Future<PrivateNote> sendNote({
    required String toName,
    required String text,
  });
  Future<POIRequest> sendPOIRequest(String debaterId);
  Future<void> acceptPOI(String poiId);
  Future<void> declinePOI(String poiId);
  Future<void> toggleMute(String participantId, {required bool mute});
  Future<void> toggleCamera(String participantId, {required bool enabled});
  Future<void> kickParticipant(String participantId);
}

/// Scoring + final upload.
abstract class ScoringRepository {
  Future<List<ScoreEntry>> draftScoresFor(String debateId);
  Future<DebateResults> uploadFinalResults({
    required String debateId,
    required List<ScoreEntry> governmentScores,
    required List<ScoreEntry> oppositionScores,
  });
}

/// Coach features: team management, priorities, join requests, live monitoring.
abstract class CoachRepository {
  Future<Team> fetchTeam();
  Future<List<JoinRequest>> fetchJoinRequests();
  Future<void> acceptJoinRequest(String requestId);
  Future<void> declineJoinRequest(String requestId);
  Future<void> reorderPriorities(List<Debater> newOrder);
  Future<List<LiveParticipant>> fetchLiveParticipants(String debateId);
  Future<List<ActivityEvent>> fetchActivityFeed(String debateId);
  Future<void> sendCoachNote({required String toDebaterName, required String text});
}

abstract class StatisticsRepository {
  Future<GeneralStatistics> fetchGeneral();
  Future<PersonalStatistics> fetchPersonal();
}
