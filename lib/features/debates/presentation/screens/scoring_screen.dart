import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/debate.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/score_entry.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/scoring_cubit.dart';
import '../widgets/team_colors.dart';

class ScoringScreen extends StatelessWidget {
  final Debate debate;
  const ScoringScreen({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScoringCubit>(
      create: (_) => ScoringCubit(
        repo: di.sl<ScoringRepository>(),
        debateId: debate.id,
        governmentDebaterIds:
            debate.governmentTeam.debaters.map((d) => d.id).toList(),
      )..load(),
      child: _ScoringView(debate: debate),
    );
  }
}

class _ScoringView extends StatelessWidget {
  final Debate debate;
  const _ScoringView({required this.debate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقييم النتائج')),
      body: BlocConsumer<ScoringCubit, ScoringState>(
        listener: (context, state) {
          if (state.uploadStatus == ScoringUploadStatus.success) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(content: Text('تم رفع النتائج بنجاح.')),
              );
            Navigator.of(context).pop();
          }
          if (state.uploadStatus == ScoringUploadStatus.error) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                  content: Text('فشل الرفع: ${state.error ?? 'خطأ'}')));
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final uploading = state.uploadStatus == ScoringUploadStatus.uploading;
          return Column(
            children: [
              _Totals(state: state),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _SectionTitle(title: 'الحكومة', side: TeamSide.government),
                    for (final s in state.governmentScores)
                      _ScoreEditor(entry: s, side: TeamSide.government),
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'المعارضة', side: TeamSide.opposition),
                    for (final s in state.oppositionScores)
                      _ScoreEditor(entry: s, side: TeamSide.opposition),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: const Text('رفع النتائج النهائية'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: uploading
                        ? null
                        : () => _confirmUpload(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmUpload(BuildContext context) async {
    final cubit = context.read<ScoringCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد رفع النتائج'),
        content: const Text(
            'هذا الإجراء لا يمكن التراجع عنه. هل أنت متأكد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (ok == true) cubit.upload();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final TeamSide side;
  const _SectionTitle({required this.title, required this.side});

  @override
  Widget build(BuildContext context) {
    final colors = TeamColors.of(side,
        isDark: Theme.of(context).brightness == Brightness.dark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                  color: colors.base,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final ScoringState state;
  const _Totals({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _TotalCard(
              label: 'الحكومة',
              total: state.governmentTotal,
              color: JadalColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TotalCard(
              label: 'المعارضة',
              total: state.oppositionTotal,
              color: JadalColors.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final int total;
  final Color color;
  const _TotalCard({required this.label, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              )),
          const SizedBox(height: 4),
          Text('$total',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              )),
        ],
      ),
    );
  }
}

class _ScoreEditor extends StatefulWidget {
  final ScoreEntry entry;
  final TeamSide side;
  const _ScoreEditor({required this.entry, required this.side});

  @override
  State<_ScoreEditor> createState() => _ScoreEditorState();
}

class _ScoreEditorState extends State<_ScoreEditor> {
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    _comment = TextEditingController(text: widget.entry.comment);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = TeamColors.of(widget.side, isDark: isDark);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colors.base.withValues(alpha: 0.18),
                child: Text(
                  widget.entry.debaterName.characters.first,
                  style: TextStyle(
                    color: colors.foreground,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.entry.debaterName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.base.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.entry.score} / 100',
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
          Slider(
            value: widget.entry.score.toDouble().clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: colors.base,
            onChanged: (v) => context
                .read<ScoringCubit>()
                .updateScore(widget.entry.debaterId, v.toInt()),
          ),
          TextField(
            controller: _comment,
            decoration: const InputDecoration(
              hintText: 'تعليق الحكم…',
              isDense: true,
            ),
            maxLines: 2,
            onChanged: (v) =>
                context.read<ScoringCubit>().updateComment(widget.entry.debaterId, v),
          ),
        ],
      ),
    );
  }
}
