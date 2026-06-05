import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/session_models.dart';
import 'team_colors.dart';

class ParticipantTile extends StatelessWidget {
  final LiveParticipant participant;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showActiveBorder;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.onTap,
    this.trailing,
    this.showActiveBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isJudge = participant.role == ParticipantRole.judge;
    final colors = isJudge
        ? const TeamColors(
            base: JadalColors.judgesGrey,
            tint: Color(0x269A9A9A),
            foreground: JadalColors.judgesGrey,
          )
        : TeamColors.of(participant.team!, isDark: isDark);

    final borderColor = showActiveBorder && participant.isActiveSpeaker
        ? JadalColors.primaryOrange
        : colors.tint;

    return _PulsingBorder(
      pulse: showActiveBorder && participant.isActiveSpeaker,
      color: borderColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.tint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.base,
                    child: Text(
                      _initial(participant.name),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      participant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: colors.foreground,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatusIcon(
                    on: participant.isMicOn,
                    iconOn: Icons.mic,
                    iconOff: Icons.mic_off,
                    color: colors.foreground,
                  ),
                  const SizedBox(width: 8),
                  _StatusIcon(
                    on: participant.isCameraOn,
                    iconOn: Icons.videocam,
                    iconOff: Icons.videocam_off,
                    color: colors.foreground,
                  ),
                  const Spacer(),
                  if (participant.currentScore != null && !isJudge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.base.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${participant.currentScore}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: colors.foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initial(String name) {
    if (name.isEmpty) return '؟';
    return name.characters.first;
  }
}

class _StatusIcon extends StatelessWidget {
  final bool on;
  final IconData iconOn;
  final IconData iconOff;
  final Color color;

  const _StatusIcon({
    required this.on,
    required this.iconOn,
    required this.iconOff,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      on ? iconOn : iconOff,
      size: 16,
      color: on ? color : color.withValues(alpha: 0.4),
    );
  }
}

class _PulsingBorder extends StatefulWidget {
  final bool pulse;
  final Color color;
  final Widget child;

  const _PulsingBorder({
    required this.pulse,
    required this.color,
    required this.child,
  });

  @override
  State<_PulsingBorder> createState() => _PulsingBorderState();
}

class _PulsingBorderState extends State<_PulsingBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final width = widget.pulse ? 1.5 + 1.5 * _ctrl.value : 1.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color, width: width),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
