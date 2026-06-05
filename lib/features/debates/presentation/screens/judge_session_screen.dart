import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/debate.dart';
import '../../domain/entities/debater.dart';
import '../../domain/entities/session_models.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/judge_session_cubit.dart';
import '../widgets/arabic_format.dart';
import '../widgets/participant_tile.dart';
import 'scoring_screen.dart';

class JudgeSessionScreen extends StatelessWidget {
  final Debate debate;
  const JudgeSessionScreen({super.key, required this.debate});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JudgeSessionCubit>(
      create: (_) => JudgeSessionCubit(
        repo: di.sl<LiveSessionRepository>(),
        debateId: debate.id,
      )..load(),
      child: _JudgeSessionView(debate: debate),
    );
  }
}

class _JudgeSessionView extends StatelessWidget {
  final Debate debate;
  const _JudgeSessionView({required this.debate});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JudgeSessionCubit, JudgeSessionState>(
      listenWhen: (a, b) => a.lastAction != b.lastAction && b.lastAction != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(state.lastAction!)));
        context.read<JudgeSessionCubit>().clearLastAction();
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(debate.title,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'رجوع للمرحلة السابقة',
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: state.isLoading
                    ? null
                    : () => context.read<JudgeSessionCubit>().retreatPhase(),
              ),
              IconButton(
                tooltip: 'المرحلة التالية',
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: state.isLoading
                    ? null
                    : () => context.read<JudgeSessionCubit>().advancePhase(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: state.allScored
                ? JadalColors.primaryOrange
                : JadalColors.judgesGrey,
            onPressed: state.allScored
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScoringScreen(debate: debate),
                      ),
                    )
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لا يمكن الرفع: لم تكتمل درجات جميع المناظرين.'),
                      ),
                    ),
            icon: const Icon(Icons.upload),
            label: const Text('رفع النتائج'),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  children: [
                    _PhaseChip(phase: state.phase),
                    const SizedBox(height: 12),
                    _TimerPanel(state: state),
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'المناظرون'),
                    const SizedBox(height: 8),
                    _ParticipantsGrid(state: state),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: 'طلبات نقاط الاستفسار (${state.poiQueue.length})',
                    ),
                    const SizedBox(height: 8),
                    if (state.poiQueue.isEmpty)
                      const _EmptyHint(text: 'لا توجد طلبات حالياً.')
                    else
                      for (final r in state.poiQueue)
                        _POITile(request: r),
                  ],
                ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ));
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final SessionPhase phase;
  const _PhaseChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: JadalColors.primaryBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag, size: 14, color: JadalColors.primaryBlue),
            const SizedBox(width: 6),
            Text(
              'المرحلة: ${phase.arabicLabel}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: JadalColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  final JudgeSessionState state;
  const _TimerPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<JudgeSessionCubit>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: JadalColors.primaryBlue),
              const SizedBox(width: 8),
              Text('مؤقت المتحدث', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(_statusLabel(state.timerStatus),
                  style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              formatCountdown(state.timerSeconds),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 38,
                color: JadalColors.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.timerStatus == SpeakerTimerStatus.running
                      ? cubit.pauseTimer
                      : cubit.startTimer,
                  icon: Icon(state.timerStatus == SpeakerTimerStatus.running
                      ? Icons.pause
                      : Icons.play_arrow),
                  label: Text(state.timerStatus == SpeakerTimerStatus.running
                      ? 'إيقاف مؤقت'
                      : 'بدء'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cubit.stopTimer,
                  icon: const Icon(Icons.stop),
                  label: const Text('إيقاف'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cubit.resetTimer,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('تصفير'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(SpeakerTimerStatus s) => switch (s) {
        SpeakerTimerStatus.stopped => 'متوقف',
        SpeakerTimerStatus.running => 'جاري',
        SpeakerTimerStatus.paused => 'متوقف مؤقتاً',
      };
}

class _ParticipantsGrid extends StatelessWidget {
  final JudgeSessionState state;
  const _ParticipantsGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final debaters = state.participants
        .where((p) => p.role == ParticipantRole.debater)
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final crossAxisCount = isWide ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 130,
          ),
          itemCount: debaters.length,
          itemBuilder: (context, i) => _JudgeParticipantCard(p: debaters[i]),
        );
      },
    );
  }
}

class _JudgeParticipantCard extends StatelessWidget {
  final LiveParticipant p;
  const _JudgeParticipantCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JudgeSessionCubit>();
    return ParticipantTile(
      participant: p,
      showActiveBorder: true,
      trailing: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_horiz, size: 18),
        onSelected: (v) {
          switch (v) {
            case 'mute':
              cubit.toggleMute(p.id);
              break;
            case 'cam':
              cubit.toggleCamera(p.id);
              break;
            case 'kick':
              _confirmKick(context, cubit);
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'mute',
            child: Text(p.isMicOn ? 'كتم الميكروفون' : 'تفعيل الميكروفون'),
          ),
          PopupMenuItem(
            value: 'cam',
            child: Text(p.isCameraOn ? 'إغلاق الكاميرا' : 'تفعيل الكاميرا'),
          ),
          const PopupMenuItem(value: 'kick', child: Text('طرد من الجلسة')),
        ],
      ),
    );
  }

  Future<void> _confirmKick(BuildContext context, JudgeSessionCubit cubit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('طرد من الجلسة'),
        content: Text('هل أنت متأكد من طرد ${p.name}؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('طرد'),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.kick(p.id);
  }
}

class _POITile extends StatelessWidget {
  final POIRequest request;
  const _POITile({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<JudgeSessionCubit>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.front_hand, color: JadalColors.primaryOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.debaterName, style: theme.textTheme.titleSmall),
                Text(
                  '${request.team == TeamSide.government ? 'الحكومة' : 'المعارضة'} • ${formatTime(request.createdAt)}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => cubit.declinePOI(request.id),
            child: const Text('ارفض'),
          ),
          ElevatedButton(
            onPressed: () => cubit.acceptPOI(request.id),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(70, 36),
            ),
            child: const Text('اقبل'),
          ),
        ],
      ),
    );
  }
}
