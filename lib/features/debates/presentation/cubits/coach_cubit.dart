import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/debater.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/debate_repositories.dart';

class CoachTeamState extends Equatable {
  final bool isLoading;
  final Team? team;
  final List<JoinRequest> joinRequests;
  final String? lastAction;

  const CoachTeamState({
    this.isLoading = true,
    this.team,
    this.joinRequests = const [],
    this.lastAction,
  });

  CoachTeamState copyWith({
    bool? isLoading,
    Team? team,
    List<JoinRequest>? joinRequests,
    String? lastAction,
    bool clearLastAction = false,
  }) =>
      CoachTeamState(
        isLoading: isLoading ?? this.isLoading,
        team: team ?? this.team,
        joinRequests: joinRequests ?? this.joinRequests,
        lastAction: clearLastAction ? null : (lastAction ?? this.lastAction),
      );

  @override
  List<Object?> get props => [isLoading, team, joinRequests, lastAction];
}

class CoachTeamCubit extends Cubit<CoachTeamState> {
  final CoachRepository _repo;

  CoachTeamCubit(this._repo) : super(const CoachTeamState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final team = await _repo.fetchTeam();
    final reqs = await _repo.fetchJoinRequests();
    emit(state.copyWith(isLoading: false, team: team, joinRequests: reqs));
  }

  Future<void> acceptRequest(String id) async {
    final req = state.joinRequests.firstWhere((r) => r.id == id);
    await _repo.acceptJoinRequest(id);
    emit(state.copyWith(
      joinRequests: state.joinRequests.where((r) => r.id != id).toList(),
      lastAction: 'تم قبول ${req.debaterName}',
    ));
  }

  Future<void> declineRequest(String id) async {
    final req = state.joinRequests.firstWhere((r) => r.id == id);
    await _repo.declineJoinRequest(id);
    emit(state.copyWith(
      joinRequests: state.joinRequests.where((r) => r.id != id).toList(),
      lastAction: 'تم رفض ${req.debaterName}',
    ));
  }

  Future<void> reorderPriorities(List<Debater> newOrder) async {
    await _repo.reorderPriorities(newOrder);
    final reprioritised = <Debater>[
      for (int i = 0; i < newOrder.length; i++) newOrder[i].copyWith(priority: i),
    ];
    emit(state.copyWith(
      team: state.team?.copyWith(debaters: reprioritised),
      lastAction: 'تم تحديث الأولويات.',
    ));
  }

  void clearLastAction() => emit(state.copyWith(clearLastAction: true));
}

class CoachMonitoringState extends Equatable {
  final bool isLoading;
  final List<LiveParticipant> participants;
  final List<ActivityEvent> activity;
  final String? lastAction;

  const CoachMonitoringState({
    this.isLoading = true,
    this.participants = const [],
    this.activity = const [],
    this.lastAction,
  });

  CoachMonitoringState copyWith({
    bool? isLoading,
    List<LiveParticipant>? participants,
    List<ActivityEvent>? activity,
    String? lastAction,
    bool clearLastAction = false,
  }) =>
      CoachMonitoringState(
        isLoading: isLoading ?? this.isLoading,
        participants: participants ?? this.participants,
        activity: activity ?? this.activity,
        lastAction: clearLastAction ? null : (lastAction ?? this.lastAction),
      );

  @override
  List<Object?> get props => [isLoading, participants, activity, lastAction];
}

class CoachMonitoringCubit extends Cubit<CoachMonitoringState> {
  final CoachRepository _repo;
  final String _debateId;

  CoachMonitoringCubit({required CoachRepository repo, required String debateId})
      : _repo = repo,
        _debateId = debateId,
        super(const CoachMonitoringState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final participants = await _repo.fetchLiveParticipants(_debateId);
    final activity = await _repo.fetchActivityFeed(_debateId);
    emit(state.copyWith(
      isLoading: false,
      participants: participants,
      activity: activity,
    ));
  }

  Future<void> sendNote({
    required String toDebaterName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    await _repo.sendCoachNote(toDebaterName: toDebaterName, text: text);
    emit(state.copyWith(lastAction: 'تم إرسال ملاحظة إلى $toDebaterName.'));
  }

  void clearLastAction() => emit(state.copyWith(clearLastAction: true));
}
