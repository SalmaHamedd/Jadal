import '../../../../core/function/json_utils.dart';

/// Coach team-summary: one scalar per metric, averaged across every
/// non-random team the coach has ever created (current + past). Deliberately
/// NOT the bucketed chart shape — the backend ships four averages, no series.
/// `teamAvgActive` is the activity score averaged across the coach's
/// CURRENT teams' current members (different in kind from the other three).
class TeamSummaryStat {
  final int teamsCounted;
  final double teamAvgImprovement;
  final double teamAvgWinRate;
  final double teamAvgScore;
  final double teamAvgActive;

  const TeamSummaryStat({
    required this.teamsCounted,
    required this.teamAvgImprovement,
    required this.teamAvgWinRate,
    required this.teamAvgScore,
    required this.teamAvgActive,
  });

  factory TeamSummaryStat.fromJson(Map<String, dynamic> j) => TeamSummaryStat(
        teamsCounted: asInt(j['teams_counted']) ?? 0,
        teamAvgImprovement: asDouble(j['team_avg_improvement']) ?? 0,
        teamAvgWinRate: asDouble(j['team_avg_win_rate']) ?? 0,
        teamAvgScore: asDouble(j['team_avg_score']) ?? 0,
        teamAvgActive: asDouble(j['team_avg_active']) ?? 0,
      );
}
