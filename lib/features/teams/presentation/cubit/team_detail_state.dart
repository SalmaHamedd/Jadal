part of 'team_detail_cubit.dart';

class TeamDetailState extends Equatable {
  final Team team;
  final bool busy;
  final String? error;
  final bool deactivated;
  final List<TeamLeaveRequest> leaveRequests;
  final bool loadingLeaveRequests;
  final List<TeamJoinRequest> joinRequests;
  final bool loadingJoinRequests;

  const TeamDetailState({
    required this.team,
    this.busy = false,
    this.error,
    this.deactivated = false,
    this.leaveRequests = const [],
    this.loadingLeaveRequests = false,
    this.joinRequests = const [],
    this.loadingJoinRequests = false,
  });

  TeamDetailState copyWith({
    Team? team,
    bool? busy,
    String? error,
    bool clearError = false,
    bool? deactivated,
    List<TeamLeaveRequest>? leaveRequests,
    bool? loadingLeaveRequests,
    List<TeamJoinRequest>? joinRequests,
    bool? loadingJoinRequests,
  }) {
    return TeamDetailState(
      team: team ?? this.team,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      deactivated: deactivated ?? this.deactivated,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      loadingLeaveRequests: loadingLeaveRequests ?? this.loadingLeaveRequests,
      joinRequests: joinRequests ?? this.joinRequests,
      loadingJoinRequests: loadingJoinRequests ?? this.loadingJoinRequests,
    );
  }

  @override
  List<Object?> get props => [
        team,
        busy,
        error,
        deactivated,
        leaveRequests,
        loadingLeaveRequests,
        joinRequests,
        loadingJoinRequests,
      ];
}
