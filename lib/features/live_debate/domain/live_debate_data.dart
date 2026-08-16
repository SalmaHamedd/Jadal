import '../../../core/app_models/motion.dart';
import '../data/models/debate_models.dart';

/// The read-only debate dataset the live-debate UI renders from.
/// Both the test/mock source ([MockLiveDebateData]) and the backend-derived
/// source (built from `GET /live-state`) implement this, so the **same widget
/// tree** can render either mode. Widgets only ever read `controller.data`
/// through this interface — never a concrete type.
abstract class LiveDebateData {
  /// Drives prep + speech timing for the whole debate.
  DebateFormat get format;

  /// The local (logged-in) user's id, used to resolve their role/side/leadership.
  /// In backend mode this is the auth `User.id` as a string.
  String get currentUserId;

  /// Debate start instant; prep rooms are open within [DebateFormat.preparationPeriod].
  DateTime get debateStartTime;

  TeamInfo get propositionTeam;
  TeamInfo get oppositionTeam;

  List<JudgeInfo> get judges;
  List<String> get judgeIds;

  Motion get motion;
  List<AudienceMember> get audience;

  /// The lobby rooms (prop / opp / live / result).
  List<DebateRoom> get rooms;

  TeamInfo? teamById(String? teamId);
}
