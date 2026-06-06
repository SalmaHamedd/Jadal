import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/debate.dart';
import 'arabic_format.dart';

class DebateCard extends StatelessWidget {
  final Debate debate;
  final VoidCallback? onTap;
  final Widget? trailingCta;

  const DebateCard({
    super.key,
    required this.debate,
    this.onTap,
    this.trailingCta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A3A55)
                  : const Color(0xFFE7ECF2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FrameworkChip(label: debate.motionFramework),
                  ),
                  _StatusBadge(status: debate.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                debate.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${debate.governmentTeam.name} × ${debate.oppositionTeam.name}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.event,
                      size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(
                    formatArabicDateTime(debate.scheduledAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (trailingCta != null) trailingCta!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrameworkChip extends StatelessWidget {
  final String label;
  const _FrameworkChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: JadalColors.primaryBlue.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: JadalColors.primaryBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DebateLifecycle status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case DebateLifecycle.upcoming:
        bg = const Color(0x1F4A90E2);
        fg = JadalColors.deepBlue;
        break;
      case DebateLifecycle.live:
        bg = JadalColors.primaryOrange.withValues(alpha: 0.16);
        fg = JadalColors.primaryOrange;
        break;
      case DebateLifecycle.past:
        bg = Colors.grey.withValues(alpha: 0.20);
        fg = Colors.grey.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == DebateLifecycle.live)
            _LivePulse(color: fg)
          else
            Icon(
              status == DebateLifecycle.upcoming
                  ? Icons.schedule
                  : Icons.check_circle_outline,
              size: 12,
              color: fg,
            ),
          const SizedBox(width: 4),
          Text(
            status.arabicLabel,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  final Color color;
  const _LivePulse({required this.color});

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.5 + 0.5 * _ctrl.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
