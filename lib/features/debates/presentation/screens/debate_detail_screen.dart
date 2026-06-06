import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../live_debate/presentation/pages/debate_lobby_screen.dart';
import '../../domain/entities/debate.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/team.dart';
import '../widgets/arabic_format.dart';
import '../widgets/team_colors.dart';

class DebateDetailScreen extends StatelessWidget {
  final Debate debate;

  const DebateDetailScreen({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المناظرة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MotionHeader(debate: debate),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TeamColumn(team: debate.governmentTeam)),
              const SizedBox(width: 12),
              Expanded(child: _TeamColumn(team: debate.oppositionTeam)),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.gavel, label: 'الحكم', value: debate.judge.name),
          _DetailRow(icon: Icons.school, label: 'المدرّب', value: debate.coach.name),
          _DetailRow(
            icon: Icons.event,
            label: 'الموعد',
            value: formatArabicDateTime(debate.scheduledAt),
          ),
          _DetailRow(icon: Icons.place, label: 'القاعة', value: debate.venue),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // A live debate opens the live-debate lobby (rooms list, §8.1).
              if (debate.status == DebateLifecycle.live) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DebateLobbyScreen()),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_ctaLabel())),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(_ctaLabel()),
          ),
          const SizedBox(height: 12),
          Text(
            'تم تسجيلك تلقائياً عند الضغط حسب دورك في النظام.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _ctaLabel() {
    switch (debate.status) {
      case DebateLifecycle.upcoming:
        return 'سجّل في المناظرة';
      case DebateLifecycle.live:
        return 'انضم الآن';
      case DebateLifecycle.past:
        return 'عرض النتائج';
    }
  }
}

class _MotionHeader extends StatelessWidget {
  final Debate debate;
  const _MotionHeader({required this.debate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Chip(label: debate.motionFramework,
                  bg: JadalColors.primaryBlue.withValues(alpha: 0.12),
                  fg: JadalColors.primaryBlue),
              const SizedBox(width: 8),
              _Chip(label: 'مناظرة', bg: theme.colorScheme.surfaceContainerHighest,
                  fg: theme.colorScheme.onSurface),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            debate.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  final Team team;
  const _TeamColumn({required this.team});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TeamColors.of(team.side, isDark: isDark);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            team.side.arabicLabel,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: colors.foreground,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            team.name,
            style: TextStyle(
              fontFamily: 'Cairo',
              color: colors.foreground.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          for (final d in team.debaters)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: colors.base.withValues(alpha: 0.18),
                    child: Text(
                      d.name.characters.first,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: colors.foreground,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
