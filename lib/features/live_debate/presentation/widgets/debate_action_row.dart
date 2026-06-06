import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';
import 'debate_settings_sheet.dart';

/// Bottom action row (§8.6): camera, mic, ask-POI, random-news, the key
/// next-state button (start → next → finish) and the 3-dots settings menu.
/// Wrapped in [AnimatedSize] for the tap-to-reveal / auto-hide behaviour (§8.5).
class DebateActionRow extends StatelessWidget {
  final bool visible;
  const DebateActionRow({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: SizedBox(
        height: visible ? 76 : 0,
        child: Visibility(
          maintainState: true,
          maintainAnimation: false,
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
              child: BlocBuilder<DebateCubit, DebateStates>(
                builder: (context, state) {
                  final cubit = context.read<DebateCubit>();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ToggleButton(
                        enabled: cubit.isMicEnabled,
                        onIcon: Icons.mic_rounded,
                        offIcon: Icons.mic_off_rounded,
                        onPressed: cubit.toggleMic,
                      ),
                      _ToggleButton(
                        enabled: cubit.isCameraEnabled,
                        onIcon: Icons.videocam_rounded,
                        offIcon: Icons.videocam_off_rounded,
                        onPressed: cubit.toggleCamera,
                      ),
                      _ActionButton(
                        icon: Icons.front_hand_rounded,
                        onPressed: cubit.sendPOIRequest,
                        highlight: cubit.isLocalAskingPOI,
                      ),
                      _ActionButton(
                        icon: Icons.campaign_rounded,
                        onPressed: () => cubit
                            .pushRandomNews((n) => '${loc.newEventHappened} $n'),
                      ),
                      _NextButton(cubit: cubit),
                      // TODO(role-gating): some sheet items become judge-only.
                      _ActionButton(
                        icon: Icons.more_vert_rounded,
                        onPressed: () => DebateSettingsSheet.show(context, cubit),
                      ),
                    ],
                  );
                },
              ),
            ),
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
  final VoidCallback onPressed;
  final bool highlight;
  const _ActionButton({required this.icon, required this.onPressed, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final color = highlight ? JadalColors.primaryOrange : DebateTheme.textPrimary(context);
    return _Circle(
      onPressed: onPressed,
      borderColor: color.withValues(alpha: highlight ? 0.6 : 0.25),
      fillColor: color.withValues(alpha: highlight ? 0.16 : 0.06),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// The next-state control (§8.6): start → next speaker → mark done.
class _NextButton extends StatelessWidget {
  final DebateCubit cubit;
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
        width: 50,
        height: 50,
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
          boxShadow: gradient
              ? [BoxShadow(color: JadalColors.primaryBlue.withValues(alpha: 0.4), blurRadius: 10)]
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}
