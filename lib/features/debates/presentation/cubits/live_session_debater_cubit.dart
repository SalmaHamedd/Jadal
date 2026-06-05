import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/session_models.dart';
import '../../domain/repositories/debate_repositories.dart';

enum POIStatus { idle, pending, accepted, declined }

class LiveSessionDebaterState extends Equatable {
  final bool isLoading;
  final List<LiveParticipant> participants;
  final SessionPhase phase;
  final bool isMyMicOn;
  final bool isMyCameraOn;
  final POIStatus poiStatus;
  final bool isMySpeakingTurn;
  final bool notesOpen;
  final List<PrivateNote> notes;
  final String myDebaterId;

  const LiveSessionDebaterState({
    this.isLoading = true,
    this.participants = const [],
    this.phase = SessionPhase.opening,
    this.isMyMicOn = true,
    this.isMyCameraOn = true,
    this.poiStatus = POIStatus.idle,
    this.isMySpeakingTurn = true,
    this.notesOpen = false,
    this.notes = const [],
    this.myDebaterId = 'd-001',
  });

  LiveSessionDebaterState copyWith({
    bool? isLoading,
    List<LiveParticipant>? participants,
    SessionPhase? phase,
    bool? isMyMicOn,
    bool? isMyCameraOn,
    POIStatus? poiStatus,
    bool? isMySpeakingTurn,
    bool? notesOpen,
    List<PrivateNote>? notes,
    String? myDebaterId,
  }) =>
      LiveSessionDebaterState(
        isLoading: isLoading ?? this.isLoading,
        participants: participants ?? this.participants,
        phase: phase ?? this.phase,
        isMyMicOn: isMyMicOn ?? this.isMyMicOn,
        isMyCameraOn: isMyCameraOn ?? this.isMyCameraOn,
        poiStatus: poiStatus ?? this.poiStatus,
        isMySpeakingTurn: isMySpeakingTurn ?? this.isMySpeakingTurn,
        notesOpen: notesOpen ?? this.notesOpen,
        notes: notes ?? this.notes,
        myDebaterId: myDebaterId ?? this.myDebaterId,
      );

  @override
  List<Object?> get props => [
        isLoading,
        participants,
        phase,
        isMyMicOn,
        isMyCameraOn,
        poiStatus,
        isMySpeakingTurn,
        notesOpen,
        notes,
        myDebaterId,
      ];
}

class LiveSessionDebaterCubit extends Cubit<LiveSessionDebaterState> {
  final LiveSessionRepository _repo;
  final String _debateId;

  LiveSessionDebaterCubit({
    required LiveSessionRepository repo,
    required String debateId,
  })  : _repo = repo,
        _debateId = debateId,
        super(const LiveSessionDebaterState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final participants = await _repo.fetchParticipants(_debateId);
    final notes = await _repo.fetchNotes();
    emit(state.copyWith(
      isLoading: false,
      participants: participants,
      notes: notes,
      isMySpeakingTurn: participants
          .where((p) => p.id == state.myDebaterId && p.isActiveSpeaker)
          .isNotEmpty,
    ));
  }

  void toggleMic() => emit(state.copyWith(isMyMicOn: !state.isMyMicOn));
  void toggleCamera() => emit(state.copyWith(isMyCameraOn: !state.isMyCameraOn));
  void toggleNotes() => emit(state.copyWith(notesOpen: !state.notesOpen));

  Future<void> requestPOI() async {
    if (state.isMySpeakingTurn || state.poiStatus == POIStatus.pending) return;
    emit(state.copyWith(poiStatus: POIStatus.pending));
    await _repo.sendPOIRequest(state.myDebaterId);
    // Mock auto-accept after a short delay for the demo flow.
    await Future.delayed(const Duration(seconds: 2));
    emit(state.copyWith(poiStatus: POIStatus.accepted));
    await Future.delayed(const Duration(seconds: 2));
    emit(state.copyWith(poiStatus: POIStatus.idle));
  }

  void advancePhase() {
    final next = switch (state.phase) {
      SessionPhase.opening => SessionPhase.rebuttal,
      SessionPhase.rebuttal => SessionPhase.closing,
      SessionPhase.closing => SessionPhase.closing,
    };
    emit(state.copyWith(phase: next));
  }

  Future<void> sendNote({
    required String toName,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final note = await _repo.sendNote(toName: toName, text: text.trim());
    emit(state.copyWith(notes: [...state.notes, note]));
  }
}
