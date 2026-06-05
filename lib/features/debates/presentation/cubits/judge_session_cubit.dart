import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/constants/debate_constants.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/repositories/debate_repositories.dart';

enum SpeakerTimerStatus { stopped, running, paused }

class JudgeSessionState extends Equatable {
  final bool isLoading;
  final List<LiveParticipant> participants;
  final List<POIRequest> poiQueue;
  final SessionPhase phase;
  final int timerSeconds;
  final SpeakerTimerStatus timerStatus;
  final String? lastAction;

  const JudgeSessionState({
    this.isLoading = true,
    this.participants = const [],
    this.poiQueue = const [],
    this.phase = SessionPhase.opening,
    this.timerSeconds = kSpeakerTurnSeconds,
    this.timerStatus = SpeakerTimerStatus.stopped,
    this.lastAction,
  });

  bool get allScored {
    final debaters =
        participants.where((p) => p.role == ParticipantRole.debater).toList();
    if (debaters.length != kDebatersPerDebate) return false;
    return debaters.every((d) => (d.currentScore ?? 0) > 0);
  }

  JudgeSessionState copyWith({
    bool? isLoading,
    List<LiveParticipant>? participants,
    List<POIRequest>? poiQueue,
    SessionPhase? phase,
    int? timerSeconds,
    SpeakerTimerStatus? timerStatus,
    String? lastAction,
    bool clearLastAction = false,
  }) =>
      JudgeSessionState(
        isLoading: isLoading ?? this.isLoading,
        participants: participants ?? this.participants,
        poiQueue: poiQueue ?? this.poiQueue,
        phase: phase ?? this.phase,
        timerSeconds: timerSeconds ?? this.timerSeconds,
        timerStatus: timerStatus ?? this.timerStatus,
        lastAction: clearLastAction ? null : (lastAction ?? this.lastAction),
      );

  @override
  List<Object?> get props => [
        isLoading,
        participants,
        poiQueue,
        phase,
        timerSeconds,
        timerStatus,
        lastAction,
      ];
}

class JudgeSessionCubit extends Cubit<JudgeSessionState> {
  final LiveSessionRepository _repo;
  final String _debateId;
  Timer? _ticker;

  JudgeSessionCubit({
    required LiveSessionRepository repo,
    required String debateId,
  })  : _repo = repo,
        _debateId = debateId,
        super(const JudgeSessionState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final participants = await _repo.fetchParticipants(_debateId);
    final poiQueue = await _repo.fetchPOIQueue();
    emit(state.copyWith(
      isLoading: false,
      participants: participants,
      poiQueue: poiQueue,
    ));
  }

  Future<void> toggleMute(String id) async {
    final target = state.participants.firstWhere((p) => p.id == id);
    final mute = target.isMicOn;
    await _repo.toggleMute(id, mute: mute);
    emit(state.copyWith(
      participants: state.participants
          .map((p) => p.id == id ? p.copyWith(isMicOn: !mute) : p)
          .toList(),
      lastAction: mute ? 'تم إيقاف الميكروفون: ${target.name}' : 'تم تفعيل الميكروفون: ${target.name}',
    ));
  }

  Future<void> toggleCamera(String id) async {
    final target = state.participants.firstWhere((p) => p.id == id);
    final next = !target.isCameraOn;
    await _repo.toggleCamera(id, enabled: next);
    emit(state.copyWith(
      participants: state.participants
          .map((p) => p.id == id ? p.copyWith(isCameraOn: next) : p)
          .toList(),
      lastAction: 'كاميرا ${target.name}: ${next ? 'مفعّلة' : 'مغلقة'}',
    ));
  }

  void startTimer() {
    _ticker?.cancel();
    emit(state.copyWith(
        timerStatus: SpeakerTimerStatus.running,
        timerSeconds: state.timerSeconds <= 0 ? kSpeakerTurnSeconds : state.timerSeconds));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timerSeconds <= 0) {
        _ticker?.cancel();
        emit(state.copyWith(timerStatus: SpeakerTimerStatus.stopped));
        return;
      }
      emit(state.copyWith(timerSeconds: state.timerSeconds - 1));
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    emit(state.copyWith(timerStatus: SpeakerTimerStatus.paused));
  }

  void stopTimer() {
    _ticker?.cancel();
    emit(state.copyWith(
      timerStatus: SpeakerTimerStatus.stopped,
      timerSeconds: 0,
    ));
  }

  void resetTimer() {
    _ticker?.cancel();
    emit(state.copyWith(
      timerStatus: SpeakerTimerStatus.stopped,
      timerSeconds: kSpeakerTurnSeconds,
    ));
  }

  Future<void> acceptPOI(String poiId) async {
    final req = state.poiQueue.firstWhere((p) => p.id == poiId);
    await _repo.acceptPOI(poiId);
    emit(state.copyWith(
      poiQueue: state.poiQueue.where((p) => p.id != poiId).toList(),
      lastAction: 'قبول نقطة استفسار من ${req.debaterName}',
    ));
  }

  Future<void> declinePOI(String poiId) async {
    final req = state.poiQueue.firstWhere((p) => p.id == poiId);
    await _repo.declinePOI(poiId);
    emit(state.copyWith(
      poiQueue: state.poiQueue.where((p) => p.id != poiId).toList(),
      lastAction: 'رفض نقطة استفسار من ${req.debaterName}',
    ));
  }

  void advancePhase() {
    final next = switch (state.phase) {
      SessionPhase.opening => SessionPhase.rebuttal,
      SessionPhase.rebuttal => SessionPhase.closing,
      SessionPhase.closing => SessionPhase.closing,
    };
    emit(state.copyWith(
      phase: next,
      lastAction: 'انتقلنا إلى ${next.arabicLabel}',
    ));
  }

  void retreatPhase() {
    final prev = switch (state.phase) {
      SessionPhase.closing => SessionPhase.rebuttal,
      SessionPhase.rebuttal => SessionPhase.opening,
      SessionPhase.opening => SessionPhase.opening,
    };
    emit(state.copyWith(
      phase: prev,
      lastAction: 'رجوع إلى ${prev.arabicLabel}',
    ));
  }

  Future<void> kick(String id) async {
    final target = state.participants.firstWhere((p) => p.id == id);
    await _repo.kickParticipant(id);
    emit(state.copyWith(
      participants: state.participants.where((p) => p.id != id).toList(),
      lastAction: 'تم طرد ${target.name}',
    ));
  }

  void clearLastAction() => emit(state.copyWith(clearLastAction: true));

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
