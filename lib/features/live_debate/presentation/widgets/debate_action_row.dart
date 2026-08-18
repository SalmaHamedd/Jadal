import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import 'debate_settings_sheet.dart';
import 'team_chat_dialog.dart';

/// Bottom action row: camera, mic, ask-POI, random-news, the key
/// next-state button (start → next → finish) and the 3-dots settings menu.
/// Wrapped in [AnimatedSize] for the tap-to-reveal / auto-hide behaviour.
class DebateActionRow extends StatelessWidget {
  final bool visible;
  const DebateActionRow({super.key, required this.visible});

  static const double kHeight = 76;

  @override
  Widget build(BuildContext context) {
    // Collapse to zero when hidden so the freed space goes back to the cards.
    // `_DebateView` redistributes it 75% to the main card / 25% to the team cards
    // (via a LayoutBuilder), so the team cards barely shrink and never overflow.
    if (!visible) return const SizedBox(height: 0, width: double.infinity);
    return SizedBox(
      height: kHeight,
      child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: DebateTheme.surfaceElevated(context),
                borderRadius: BorderRadius.circular(widgetBorderRadius),
                border: Border.all(
                  color: JadalColors.primaryBlue.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BlocBuilder<DebateController, DebateStates>(
                builder: (context, state) {
                  final cubit = context.read<DebateController>();
                  // Role gating: controls a role can't use are hidden; the
                  // POI button stays visible but disabled outside its window.
                  // Test mode returns all flags true, so it shows everything.
                  final buttons = <Widget>[
                      if (cubit.canUseMedia)
                        // Publish-locked (chair mute-all / per-user) → disabled.
                        cubit.canPublishNow
                            ? _ToggleButton(
                                enabled: cubit.isMicEnabled,
                                onIcon: Icons.mic_rounded,
                                offIcon: Icons.mic_off_rounded,
                                onPressed: cubit.toggleMic,
                              )
                            : const _ActionButton(
                                icon: Icons.mic_off_rounded,
                                onPressed: null,
                              ),
                      if (cubit.canUseMedia)
                        // Camera-locked (chair camera-all / per-user) → disabled,
                        // mirroring the mic lock above.
                        cubit.canEnableCameraNow
                            ? _ToggleButton(
                                enabled: cubit.isCameraEnabled,
                                onIcon: Icons.videocam_rounded,
                                offIcon: Icons.videocam_off_rounded,
                                onPressed: cubit.toggleCamera,
                              )
                            : const _ActionButton(
                                icon: Icons.videocam_off_rounded,
                                onPressed: null,
                              ),
                      if (cubit.canAskPoi) _PoiButton(cubit: cubit),
                      // The next-stage control belongs to the live debate only;
                      // the open lobby has its own "Back to debate" button.
                      if (cubit.canControlStage && !cubit.isLobbyMode)
                        _NextButton(cubit: cubit),
                      // Team chat lives in the toolbar now (out of the 3-dots), with
                      // an unread dot so a new message gets noticed.
                      if (cubit.canOpenChat) _ChatButton(cubit: cubit),
                      _ActionButton(
                        icon: Icons.more_vert_rounded,
                        onPressed: () => DebateSettingsSheet.show(context, cubit),
                      ),
                    ];
                  // A panel judge in the result phase is left with two or three
                  // controls; spread evenly they read as stray dots rather than
                  // a tool bar, so a short row is grouped in the middle instead.
                  final spread = buttons.length > 3;
                  return Row(
                    mainAxisAlignment: spread
                        ? MainAxisAlignment.spaceEvenly
                        : MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < buttons.length; i++) ...[
                        if (!spread && i > 0) const SizedBox(width: 22),
                        buttons[i],
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool enabled;
  final IconData onIcon;
  final IconData offIcon;
  final VoidCallback onPressed;
  const _ToggleButton({
    required this.enabled,
    required this.onIcon,
    required this.offIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? JadalColors.primaryBlue : DebateTheme.textSecondary(context);
    return _Circle(
      onPressed: onPressed,
      borderColor: color.withValues(alpha: 0.4),
      fillColor: color.withValues(alpha: 0.12),
      child: Icon(enabled ? onIcon : offIcon, color: color, size: 22),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;

  /// Null → the button is shown but disabled/greyed (e.g. POI outside its window).
  final VoidCallback? onPressed;
  final bool highlight;
  const _ActionButton({required this.icon, required this.onPressed, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final base = highlight ? JadalColors.primaryOrange : DebateTheme.textPrimary(context);
    final color = disabled ? DebateTheme.textSecondary(context).withValues(alpha: 0.4) : base;
    return _Circle(
      onPressed: onPressed,
      borderColor: color.withValues(alpha: highlight ? 0.6 : 0.25),
      fillColor: color.withValues(alpha: highlight ? 0.16 : 0.06),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// The POI button. One control for the whole hand-raise cycle: raise, tap again
/// to take it back down, and — once it has gone down for any reason — a short
/// wait before the next one. The wait shows as a countdown rather than a dead
/// grey button, so it reads as a rule instead of a fault.
class _PoiButton extends StatelessWidget {
  final DebateController cubit;
  const _PoiButton({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final asking = cubit.isLocalAskingPOI;
    final cooling = cubit.isPoiCoolingDown;
    // Lowering must stay possible even after the POI window shuts, or a hand
    // raised on the last legal second would be stuck up.
    final canPress = asking || (cubit.poiEnabledNow && !cooling);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ActionButton(
          icon: Icons.front_hand_rounded,
          onPressed: canPress ? cubit.togglePOI : null,
          highlight: asking,
        ),
        if (cooling && !asking)
          PositionedDirectional(
            top: -1,
            end: -1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DebateTheme.textSecondary(context),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: DebateTheme.surfaceElevated(context), width: 1.5),
              ),
              child: Text(
                '${cubit.poiCooldownRemainingSeconds}',
                style: AppTextStyles.small(context)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1),
              ),
            ),
          ),
      ],
    );
  }
}

/// Team-chat toolbar button: opens the team chat dialog and carries an unread
/// notification dot when messages arrived while it was closed.
class _ChatButton extends StatelessWidget {
  final DebateController cubit;
  const _ChatButton({required this.cubit});

  void _open(BuildContext context) {
    // The dialog itself flips the cubit's "chat open" flag (init/dispose), so the
    // unread counter clears on open and resumes counting on close.
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: TeamChatDialog(teamId: cubit.myChatChannelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = cubit.unreadTeamChatCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ActionButton(
          icon: Icons.forum_rounded,
          onPressed: () => _open(context),
        ),
        // A plain dot, not a tally: mid-debate the useful signal is "someone on
        // your side said something", not how many times.
        if (unread)
          PositionedDirectional(
            top: -1,
            end: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: JadalColors.primaryOrange,
                shape: BoxShape.circle,
                border: Border.all(color: DebateTheme.surfaceElevated(context), width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// The next-state control: start → next speaker → mark done.
class _NextButton extends StatelessWidget {
  final DebateController cubit;
  const _NextButton({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    if (!cubit.debateStarted) {
      icon = Icons.play_arrow_rounded;
    } else if (cubit.isLastStep) {
      icon = Icons.flag_rounded;
    } else {
      icon = Icons.skip_next_rounded;
    }
    final disabled = cubit.debateFinished;
    // TODO(role-gating): judge-only in production.
    return _Circle(
      onPressed: disabled ? null : cubit.advanceDebate,
      gradient: !disabled,
      borderColor: Colors.transparent,
      fillColor: Colors.transparent,
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _Circle extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color fillColor;
  final bool gradient;
  const _Circle({
    required this.child,
    required this.onPressed,
    required this.borderColor,
    required this.fillColor,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient ? null : fillColor,
          gradient: gradient
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [JadalColors.primaryBlue, JadalColors.primaryOrange],
                )
              : null,
          border: Border.all(color: borderColor, width: 1.5),
          // No glow on the next-stage button — it read as too much.
        ),
        child: Center(child: child),
      ),
    );
  }
}
