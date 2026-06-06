import 'package:flutter/material.dart';

import '../../domain/entities/debate.dart';
import '../../domain/entities/debate_results.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/score_entry.dart';
import '../widgets/team_colors.dart';

class PostSessionResultsScreen extends StatelessWidget {
  final Debate debate;
  const PostSessionResultsScreen({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    final results = debate.results;
    return Scaffold(
      appBar: AppBar(title: const Text('نتائج المناظرة')),
      body: results == null
          ? const Center(child: Text('لا توجد نتائج بعد.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WinnerBanner(debate: debate, results: results),
                const SizedBox(height: 20),
                _ScoresSection(
                  title: 'الحكومة',
                  side: TeamSide.government,
                  scores: results.governmentScores,
                ),
                const SizedBox(height: 16),
                _ScoresSection(
                  title: 'المعارضة',
                  side: TeamSide.opposition,
                  scores: results.oppositionScores,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                          content: Text('سيتم فتح نموذج التقييم.'))),
                  icon: const Icon(Icons.rate_review),
                  label: const Text('تقييم التجربة'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  final Debate debate;
  final DebateResults results;
  const _WinnerBanner({required this.debate, required this.results});

  @override
  Widget build(BuildContext context) {
    final winningTeam = results.winningSide == TeamSide.government
        ? debate.governmentTeam
        : debate.oppositionTeam;
    final colors = TeamColors.of(results.winningSide,
        isDark: Theme.of(context).brightness == Brightness.dark);
    final winningTotal = results.winningSide == TeamSide.government
        ? results.governmentTotal
        : results.oppositionTotal;
    final losingTotal = results.winningSide == TeamSide.government
        ? results.oppositionTotal
        : results.governmentTotal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.base, colors.base.withValues(alpha: 0.7)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white),
              SizedBox(width: 6),
              Text('الفائز',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            winningTeam.name,
            style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            results.winningSide.arabicLabel,
            style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ScorePill(label: 'الفائز', value: winningTotal),
              const SizedBox(width: 8),
              _ScorePill(label: 'المنافس', value: losingTotal),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int value;
  const _ScorePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Cairo',
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScoresSection extends StatelessWidget {
  final String title;
  final TeamSide side;
  final List<ScoreEntry> scores;
  const _ScoresSection({
    required this.title,
    required this.side,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TeamColors.of(side, isDark: isDark);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                color: colors.base, borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final s in scores)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.debaterName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.base.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${s.score} / 100',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: colors.foreground,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.comment,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

