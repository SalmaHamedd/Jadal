import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  final String name;
  final int totalScore;
  final int wins;

  const LeaderboardEntry({
    required this.name,
    required this.totalScore,
    required this.wins,
  });

  @override
  List<Object?> get props => [name, totalScore, wins];
}

class FrameworkWinRate extends Equatable {
  final String framework;
  final double winRate;

  const FrameworkWinRate({required this.framework, required this.winRate});

  @override
  List<Object?> get props => [framework, winRate];
}

class GeneralStatistics extends Equatable {
  final int totalDebates;
  final List<LeaderboardEntry> leaderboard;
  final List<FrameworkWinRate> winRateByFramework;

  const GeneralStatistics({
    required this.totalDebates,
    required this.leaderboard,
    required this.winRateByFramework,
  });

  @override
  List<Object?> get props => [totalDebates, leaderboard, winRateByFramework];
}

class DebateHistoryEntry extends Equatable {
  final String debateId;
  final String title;
  final DateTime date;
  final int score;
  final bool win;

  const DebateHistoryEntry({
    required this.debateId,
    required this.title,
    required this.date,
    required this.score,
    required this.win,
  });

  @override
  List<Object?> get props => [debateId, title, date, score, win];
}

class PersonalStatistics extends Equatable {
  final double winRate;
  final List<int> scoreTrend; // last 5 debates
  final List<DebateHistoryEntry> history;

  const PersonalStatistics({
    required this.winRate,
    required this.scoreTrend,
    required this.history,
  });

  @override
  List<Object?> get props => [winRate, scoreTrend, history];
}
