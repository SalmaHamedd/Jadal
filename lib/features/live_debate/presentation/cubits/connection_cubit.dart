import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'connection_state.dart';

/// Drives the tap-to-reveal / auto-hide behaviour of the bottom action row
/// (§8.5). Ported from the legacy `ConnectionCubit`.
class ConnectionCubit extends Cubit<ConnectionStates> {
  ConnectionCubit() : super(ConnectionInitialState());

  /// Was 3500ms (too quick to aim at), then briefly 8000ms (too long — the bar
  /// overstayed). 5000ms is the settled value. Every reveal path and
  /// [resetHideTimer] share this one constant.
  static const Duration _hideAfter = Duration(milliseconds: 5000);

  bool showActions = false;

  /// The participant card currently selected (its 3-dots is shown, §9.2). Null
  /// when nothing is selected.
  String? selectedParticipantId;
  Timer? _hideTimer;

  void toggleActionsVisibility() {
    showActions = !showActions;
    if (!showActions) selectedParticipantId = null;
    emit(ShowActionsState());
    _hideTimer?.cancel();
    if (showActions) {
      _hideTimer = Timer(_hideAfter, () {
        showActions = false;
        selectedParticipantId = null;
        if (!isClosed) emit(ShowActionsState());
      });
    }
  }

  /// Selecting a participant card reveals its 3-dots **and** the action row (§9.2/§9.3).
  void selectParticipant(String id) {
    selectedParticipantId = selectedParticipantId == id ? null : id;
    showActions = true;
    emit(ShowActionsState());
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideAfter, () {
      showActions = false;
      selectedParticipantId = null;
      if (!isClosed) emit(ShowActionsState());
    });
  }

  /// Restarts the auto-hide countdown (call when the user interacts with the
  /// visible action row).
  void resetHideTimer() {
    _hideTimer?.cancel();
    if (showActions) {
      _hideTimer = Timer(_hideAfter, () {
        showActions = false;
        if (!isClosed) emit(ShowActionsState());
      });
    }
  }

  @override
  Future<void> close() {
    _hideTimer?.cancel();
    return super.close();
  }
}
