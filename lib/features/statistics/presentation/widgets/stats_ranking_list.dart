import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/debater_stats_models.dart';
import 'stats_theme.dart';

/// The score-ranking list (stat 3). Each row animates in with a small staggered
/// fade+slide so switching ranking mode (top/bottom/latest/earliest) reads as
/// the list re-dealing itself.
class StatsRankingList extends StatelessWidget {
  final ScoreRanking data;
  const StatsRankingList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No qualifying debates yet.',
            style: TextStyle(fontFamily: 'Cairo', color: StatsTheme.textSecondary(context)),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '${data.totalQualifyingDebates} qualifying debates',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: StatsTheme.textSecondary(context),
            ),
          ),
        ),
        for (var i = 0; i < data.entries.length; i++)
          _RankRow(
            // Re-key per mode so the entrance animation replays on mode change.
            key: ValueKey('${data.rankingMode}-${data.entries[i].debateId}'),
            index: i,
            entry: data.entries[i],
          ),
      ],
    );
  }
}

class _RankRow extends StatefulWidget {
  final int index;
  final RankingEntry entry;
  const _RankRow({super.key, required this.index, required this.entry});

  @override
  State<_RankRow> createState() => _RankRowState();
}

class _RankRowState extends State<_RankRow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    // Stagger by index for a "dealt" feel; cap so long lists don't lag.
    Future.delayed(Duration(milliseconds: 50 * (widget.index.clamp(0, 8))), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final won = e.debateWon;
    final accent = e.side == 'proposition' ? JadalColors.primaryBlue : JadalColors.primaryOrange;

    return FadeTransition(
      opacity: _c,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StatsTheme.surface(context).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StatsTheme.border(context)),
          ),
          child: Row(
            children: [
              // Rank number.
              SizedBox(
                width: 26,
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: StatsTheme.textSecondary(context),
                  ),
                ),
              ),
              // Score dial.
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                ),
                child: Text(
                  e.normalizedScore.toStringAsFixed(0),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.motionText.isNotEmpty ? e.motionText : 'Debate #${e.debateId}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        height: 1.3,
                        color: StatsTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MiniTag(text: e.debateDate),
                        if (e.frameworkLabel != null) _MiniTag(text: e.frameworkLabel!),
                        for (final p in e.positionsHeld) _MiniTag(text: p, accent: accent),
                        if (e.rawReplyScore != null)
                          _MiniTag(text: 'reply ${e.rawReplyScore}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _WinBadge(won: won),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color? accent;
  const _MiniTag({required this.text, this.accent});

  @override
  Widget build(BuildContext context) {
    final c = accent ?? StatsTheme.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: accent ?? StatsTheme.textSecondary(context),
        ),
      ),
    );
  }
}

class _WinBadge extends StatelessWidget {
  final bool won;
  const _WinBadge({required this.won});

  @override
  Widget build(BuildContext context) {
    final color = won ? const Color(0xFF2E9E5B) : const Color(0xFFE53935);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(won ? Icons.emoji_events_rounded : Icons.close_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            won ? 'Won' : 'Lost',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
