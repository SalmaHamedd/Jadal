import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../data/models/attendance_stat_model.dart';
import '../../data/repositories/attendance_stats_repository.dart';
import '../widgets/attendance_bar_chart.dart';
import '../widgets/stats_theme.dart';

/// Single-metric attendance screen shared by debater (prep-room), coach/
/// trainer (own team's debates) and judge (assigned debates) — sprinkles
/// §6.5. Each role hits its own endpoint but renders identically; only the
/// title/subtitle copy changes.
class AttendanceStatsScreen extends StatefulWidget {
  final AttendanceRole role;
  final int userId;
  final String userName;
  const AttendanceStatsScreen({
    super.key,
    required this.role,
    required this.userId,
    required this.userName,
  });

  @override
  State<AttendanceStatsScreen> createState() => _AttendanceStatsScreenState();
}

class _AttendanceStatsScreenState extends State<AttendanceStatsScreen> {
  final _repo = AttendanceStatsRepository();
  AttendanceStat? _stat;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.getAttendance(widget.role, widget.userId);
    if (!mounted) return;
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (s) => setState(() {
        _stat = s;
        _loading = false;
      }),
    );
  }

  String _subtitle(BuildContext context) => switch (widget.role) {
    AttendanceRole.debater => context.loc.statsAttendanceSubtitleDebater,
    AttendanceRole.trainer => context.loc.statsAttendanceSubtitleTrainer,
    AttendanceRole.judge => context.loc.statsAttendanceSubtitleJudge,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StatsTheme.isDark(context)
          ? JadalColors.darkBackground
          : JadalColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          context.loc.statsAttendanceTitle(widget.userName),
          style: AppTextStyles.title(context),
        ),
      ),
      body: JadalGradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(context),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _load,
                        child: Text(context.loc.retry),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    _subtitle(context),
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: StatsTheme.textSecondary(context)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: StatsTheme.isDark(context)
                          ? JadalColors.darkSurface
                          : JadalColors.lightSurface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.loc.statsOverallPercent(
                                ((_stat?.rate ?? 0) * 100).round(),
                              ),
                              style: AppTextStyles.subtitle(context).copyWith(
                                fontWeight: FontWeight.w800,
                                color: StatsTheme.textPrimary(context),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: JadalColors.primaryOrange.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                context.loc.statsAttendedCount(
                                  _stat?.attendedTotal ?? 0,
                                  _stat?.selectedTotal ?? 0,
                                ),
                                style: AppTextStyles.small(context).copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: JadalColors.primaryOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((_stat?.registered ?? 0) >
                            (_stat?.selectedTotal ?? 0))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              context.loc.statsRegisteredNotHeldAgainst(
                                _stat!.registered,
                              ),
                              style: AppTextStyles.small(context).copyWith(
                                color: StatsTheme.textSecondary(context),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        AttendanceBarChart(buckets: _stat?.buckets ?? const []),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
