import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../domain/speech_detail.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import '../utils/name_text.dart';
import '../widgets/debate_screen_header.dart';
import '../widgets/participant_avatar.dart';

/// The judges' per-speech review: pick a speech at the top, read its transcript
/// and how it went underneath.
///
/// Opened from the result room as a pushed route, so the judge never leaves the
/// LiveKit room while reading.
class SpeechReviewScreen extends StatefulWidget {
  const SpeechReviewScreen({super.key});

  @override
  State<SpeechReviewScreen> createState() => _SpeechReviewScreenState();
}

class _SpeechReviewScreenState extends State<SpeechReviewScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      // No action row here on purpose: this is a reading screen, and the mic
      // and camera controls belong to the room the judge is still sitting in.
      body: JadalGradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              DebateScreenHeader(title: loc.reviewSpeeches),
              Expanded(
                child: BlocBuilder<DebateController, DebateStates>(
                  buildWhen: (_, s) => s is LiveStateUpdatedState,
                  builder: (context, _) {
                    final speeches = context.read<DebateController>().speechDetails;
                    if (speeches.isEmpty) return _Empty(message: loc.noSpeechesYet);
                    final index = _selected.clamp(0, speeches.length - 1);
                    return Column(
                      children: [
                        _SpeechSelector(
                          speeches: speeches,
                          selected: index,
                          onSelect: (i) => setState(() => _selected = i),
                        ),
                        Expanded(child: _SpeechBody(speech: speeches[index])),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The horizontal strip of speeches, in speaking order and coloured by side.
class _SpeechSelector extends StatelessWidget {
  final List<SpeechDetail> speeches;
  final int selected;
  final ValueChanged<int> onSelect;

  const _SpeechSelector({
    required this.speeches,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: speeches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = speeches[i];
          final active = i == selected;
          final accent = s.side != null
              ? DebateTheme.sideColor(s.side!)
              : JadalColors.judgesGrey;
          return Material(
            color: active ? accent : accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                constraints: const BoxConstraints(minWidth: 76, maxWidth: 190),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: active ? 1 : 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!s.delivered) ...[
                      Icon(Icons.schedule_rounded,
                          size: 14,
                          color: active ? Colors.white : accent),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The selected speech: who gave it, how it went, and its transcript.
class _SpeechBody extends StatelessWidget {
  final SpeechDetail speech;
  const _SpeechBody({required this.speech});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final accent = speech.side != null
        ? DebateTheme.sideColor(speech.side!)
        : JadalColors.judgesGrey;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            ParticipantAvatar(
              participantId: speech.speakerId ?? speech.label,
              name: speech.speakerName,
              avatarUrl: speech.speakerAvatarUrl,
              diameter: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speech.speakerName.isNotEmpty ? speech.speakerName : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: directionOfName(speech.speakerName),
                    style: AppTextStyles.title(context)
                        .copyWith(color: DebateTheme.textPrimary(context)),
                  ),
                  Text(
                    speech.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(context)
                        .copyWith(color: accent, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          loc.speechDetails,
          style: AppTextStyles.subtitle(context)
              .copyWith(color: DebateTheme.textPrimary(context)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Stat(
              icon: Icons.timer_outlined,
              label: loc.allottedTimeLabel,
              value: _clock(speech.allottedSeconds),
              accent: accent,
            ),
            _Stat(
              icon: Icons.timelapse_rounded,
              label: loc.timeTakenLabel,
              value: _clock(speech.takenSeconds),
              accent: accent,
            ),
            _Stat(
              icon: Icons.front_hand_outlined,
              label: loc.poisOfferedLabel,
              value: '${speech.poisOffered}',
              accent: accent,
            ),
            _Stat(
              icon: Icons.front_hand_rounded,
              label: loc.poisTakenLabel,
              value: '${speech.poisTaken}',
              accent: accent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          loc.speechTranscript,
          style: AppTextStyles.subtitle(context)
              .copyWith(color: DebateTheme.textPrimary(context)),
        ),
        const SizedBox(height: 8),
        _Transcript(speech: speech),
      ],
    );
  }

  /// `m:ss`, or a dash when the value is unknown.
  static String _clock(int? seconds) {
    if (seconds == null) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DebateTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small(context)
                      .copyWith(color: DebateTheme.textSecondary(context)),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyEmphasis(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: DebateTheme.textPrimary(context),
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

/// The transcript, or an honest account of why there isn't one. A speech that
/// hasn't happened and a transcript that hasn't arrived are different things,
/// and neither is an empty box.
class _Transcript extends StatelessWidget {
  final SpeechDetail speech;
  const _Transcript({required this.speech});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final container = BoxDecoration(
      color: DebateTheme.surfaceElevated(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: JadalColors.primaryBlue.withValues(alpha: 0.18)),
    );

    switch (speech.transcriptState) {
      case TranscriptState.ready:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: container,
          child: SelectableText(
            speech.speechText!.trim(),
            style: AppTextStyles.body(context)
                .copyWith(height: 1.6, color: DebateTheme.textPrimary(context)),
          ),
        );
      case TranscriptState.pending:
        return _Note(
          icon: Icons.hourglass_top_rounded,
          message: loc.transcriptPending,
          decoration: container,
        );
      case TranscriptState.notDelivered:
        return _Note(
          icon: Icons.schedule_rounded,
          message: loc.speechNotStarted,
          decoration: container,
        );
    }
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String message;
  final BoxDecoration decoration;
  const _Note({required this.icon, required this.message, required this.decoration});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Row(
        children: [
          Icon(icon, color: JadalColors.judgesGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body(context)
                  .copyWith(color: DebateTheme.textSecondary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;
  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.record_voice_over_outlined,
                size: 56, color: JadalColors.judgesGrey),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context)
                  .copyWith(color: DebateTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }
}
