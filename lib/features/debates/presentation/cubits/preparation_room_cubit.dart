import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/session_models.dart';
import '../../domain/repositories/debate_repositories.dart';

class PreparationRoomState extends Equatable {
  final bool isLoading;
  final int countdownSeconds;
  final List<PrepChatMessage> messages;

  const PreparationRoomState({
    this.isLoading = true,
    this.countdownSeconds = 0,
    this.messages = const [],
  });

  bool get canEnterSession => countdownSeconds <= 0;

  PreparationRoomState copyWith({
    bool? isLoading,
    int? countdownSeconds,
    List<PrepChatMessage>? messages,
  }) =>
      PreparationRoomState(
        isLoading: isLoading ?? this.isLoading,
        countdownSeconds: countdownSeconds ?? this.countdownSeconds,
        messages: messages ?? this.messages,
      );

  @override
  List<Object?> get props => [isLoading, countdownSeconds, messages];
}

class PreparationRoomCubit extends Cubit<PreparationRoomState> {
  final PreparationRoomRepository _repo;
  final String _debateId;
  Timer? _ticker;

  PreparationRoomCubit({
    required PreparationRoomRepository repo,
    required String debateId,
  })  : _repo = repo,
        _debateId = debateId,
        super(const PreparationRoomState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final seconds = await _repo.initialCountdownSeconds();
    final chat = await _repo.fetchChat(_debateId);
    emit(state.copyWith(
      isLoading: false,
      countdownSeconds: seconds,
      messages: chat,
    ));
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.countdownSeconds <= 0) {
        _ticker?.cancel();
        return;
      }
      emit(state.copyWith(countdownSeconds: state.countdownSeconds - 1));
    });
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msg = await _repo.sendMessage(_debateId, trimmed);
    emit(state.copyWith(messages: [...state.messages, msg]));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
