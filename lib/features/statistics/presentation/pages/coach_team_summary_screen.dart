import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/error/failure_text.dart';
import '../../../../core/widgets/jadal_error_view.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../data/models/team_analysis_models.dart';
import '../../data/models/team_summary_model.dart';
import '../../data/repositories/team_analysis_repository.dart';
import '../../data/repositories/team_summary_repository.dart';
import '../utils/stats_excel_exporter.dart';
import '../widgets/stats_theme.dart';
import 'coach_team_detail_screen.dart';

/// V2 §3 — the coach's team analysis: four averages across the teams they
/// train (improvement / win rate / score / member activity), one tile each.
/// A deliberately simple screen — the backend ships scalars, not series.
class CoachTeamSummaryScreen extends StatefulWidget {
  final int trainerId;
  final String? trainerName;
  const CoachTeamSummaryScreen({
    super.key,
    required this.trainerId,
    this.trainerName,
  });

  @override
  State<CoachTeamSummaryScreen> createState() => _CoachTeamSummaryScreenState();
}

class _CoachTeamSummaryScreenState extends State<CoachTeamSummaryScreen> {
  final _repo = TeamSummaryRepository();
  final _analysisRepo = TeamAnalysisRepository();
  TeamSummaryStat? _stat;
  String? _error;

  /// MF_FU §9.1 — the coach's teams, for the picker. Null id = "All teams",
  /// which is the endpoint's original all-teams-averaged behaviour.
  List<TrainerTeam> _teams = const [];
  int? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _load();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final res = await _analysisRepo.getTrainerTeams(widget.trainerId);
    if (!mounted) return;
    // A failure here just means no picker — the all-teams view still works.
    res.fold((_) {}, (list) => setState(() => _teams = list));
  }

  Future<void> _load() async {
    setState(() {
      _stat = null;
      _error = null;
    });
    final res = await _repo.getTeamSummary(
      widget.trainerId,
      teamId: _selectedTeamId,
    );
    if (!mounted) return;
    res.fold(
      (f) => setState(() => _error = f.message),
      (s) => setState(() => _stat = s),
    );
  }

  void _selectTeam(int? teamId) {
    if (teamId == _selectedTeamId) return;
    setState(() => _selectedTeamId = teamId);
    _load();
  }

  Future<void> _export() async {
    final stat = _stat;
    if (stat == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final shareText = context.loc.statsShareText;
    final shareSubject = context.loc.statsShareSubject;
    final exportFailed = context.loc.statsExportFailed;
    final nothingToExport = context.loc.statsNothingToExport;
    try {
      final bytes = StatsExcelExporter.buildTeamSummary(
        scopeLabel: _selectedTeam?.name ?? context.loc.statsAllTeams,
        teamsCounted: stat.teamsCounted,
        improvement: stat.teamAvgImprovement,
        winRate: stat.teamAvgWinRate,
        avgScore: stat.teamAvgScore,
        memberActivity: stat.teamAvgActive,
      );
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(nothingToExport)));
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${StatsExcelExporter.teamFileName('summary')}',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: shareSubject,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(exportFailed('$e'))));
    }
  }

  TrainerTeam? get _selectedTeam {
    for (final t in _teams) {
      if (t.id == _selectedTeamId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.isDark(context)
          ? JadalColors.darkBackground
          : JadalColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.trainerName == null
              ? context.loc.statsTeamAnalysisTitle
              : context.loc.statsTeamAnalysisTitleWithName(widget.trainerName!),
          style: AppTextStyles.title(context),
        ),
        actions: [
          IconButton(
            tooltip: context.loc.statsExportTooltip,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _stat == null ? null : _export,
          ),
        ],
      ),
      body: JadalGradientBackground(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return JadalErrorScrollView(
        message: FailureText.fromMessage(context, _error),
        onRetry: _load,
      );
    }
    final stat = _stat;
    final selected = _selectedTeam;
    return RefreshIndicator(
      color: JadalColors.primaryOrange,
      onRefresh: () async {
        await Future.wait([_load(), _loadTeams()]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // MF_FU §9.1 — team picker. "All teams" first (the original averaged
          // behaviour), then active teams, then past ones.
          if (_teams.isNotEmpty) ...[
            _TeamPicker(
              teams: _teams,
              selectedId: _selectedTeamId,
              onSelect: _selectTeam,
            ),
            const SizedBox(height: 14),
          ],
          if (stat == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selected == null
                        ? context.loc.statsAveragedAcrossTeams
                        : context.loc.statsForTeam(selected.name),
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: StatsTheme.textSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: JadalColors.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.loc.statsTeamsCount(stat.teamsCounted),
                    style: AppTextStyles.small(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: JadalColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.trending_up_rounded,
                    label: context.loc.statsAvgImprovement,
                    // MF_FU §7.5 — arrow + sign, never colour alone.
                    value: signedWithArrow(stat.teamAvgImprovement),
                    color: stat.teamAvgImprovement >= 0
                        ? JadalColors.positiveGreen
                        : JadalColors.negativeRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.percent_rounded,
                    label: context.loc.statsAvgWinRate,
                    value: '${(stat.teamAvgWinRate * 100).toStringAsFixed(0)}%',
                    color: JadalColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.speed_rounded,
                    label: context.loc.statsKindAvgScore,
                    value: stat.teamAvgScore.toStringAsFixed(1),
                    color: JadalColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.local_fire_department_rounded,
                    label: context.loc.statsAvgMemberActivity,
                    value: signedWithArrow(stat.teamAvgActive),
                    color: stat.teamAvgActive >= 0
                        ? JadalColors.positiveGreen
                        : JadalColors.negativeRed,
                  ),
                ),
              ],
            ),
            // MF_FU §9.2 — a specific team unlocks the full filtered breakdown
            // (and the line-up analysis). Meaningless for the all-teams average,
            // so it only appears with a team selected.
            if (selected != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoachTeamDetailScreen(
                        teamId: selected.id,
                        teamName: selected.name,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.insights_rounded),
                  label: Text(context.loc.statsSeeDetails),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// MF_FU §9.1 — "All teams" plus one chip per coached team. Active teams sort
/// first (the backend already orders them that way); past teams keep a "past"
/// pill so a wound-down team is still analysable but visibly historic.
class _TeamPicker extends StatelessWidget {
  final List<TrainerTeam> teams;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const _TeamPicker({
    required this.teams,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _TeamChip(
            label: context.loc.statsAllTeams,
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          for (final t in teams) ...[
            const SizedBox(width: 8),
            _TeamChip(
              label: t.name,
              past: !t.isActive,
              selected: selectedId == t.id,
              onTap: () => onSelect(t.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool past;
  final VoidCallback onTap;

  const _TeamChip({
    required this.label,
    required this.selected,
    this.past = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = StatsTheme.isDark(context);
    final accent = past ? JadalColors.judgesGrey : JadalColors.primaryBlue;
    final radius = BorderRadius.circular(30);
    return Material(
      color: selected
          ? accent.withValues(alpha: dark ? 0.28 : 0.16)
          : (dark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7)),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? StatsTheme.textPrimary(context)
                      : StatsTheme.textSecondary(context),
                ),
              ),
              if (past) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: JadalColors.judgesGrey.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.loc.statsTeamPast,
                    style: AppTextStyles.small(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: StatsTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: Text(
              value,
              style: AppTextStyles.displayTitle(context).copyWith(color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w700,
              color: StatsTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
