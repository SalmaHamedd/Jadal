import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'connection_state.dart';

/// Drives the tap-to-reveal / auto-hide behaviour of the bottom action row
/// (§8.5). Ported from the legacy `ConnectionCubit`.
class ConnectionCubit extends Cubit<ConnectionStates> {
  ConnectionCubit() : super(ConnectionInitialState());

  static const Duration _hideAfter = Duration(milliseconds: 3500);

  bool showActions = false;
  Timer? _hideTimer;

  void toggleActionsVisibility() {
    showActions = !showActions;
    emit(ShowActionsState());
    _hideTimer?.cancel();
    if (showActions) {
      _hideTimer = Timer(_hideAfter, () {
        showActions = false;
        if (!isClosed) emit(ShowActionsState());
      });
    }
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
