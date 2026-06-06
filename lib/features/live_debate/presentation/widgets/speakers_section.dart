import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/debate_models.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';
import 'speaker_card.dart';

/// Speakers section (§8.3 C): 3 proposition cards on the left (blue), 3
/// opposition cards on the right (orange).
class SpeakersSection extends StatelessWidget {
  /// Whether the local viewer can moderate (open the tap dialog). In test mode
  /// this is true so the tester can exercise it.
  // TODO(role-gating): true only for viewers/audience.
  final bool canModerate;

  const SpeakersSection({super.key, this.canModerate = true});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebateCubit, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateCubit>();
        return Row(
          children: [
            Expanded(child: _column(context, cubit, DebateSide.proposition)),
            const SizedBox(width: 10),
            Expanded(child: _column(context, cubit, DebateSide.opposition)),
          ],
        );
      },
    );
  }

  Widget _column(BuildContext context, DebateCubit cubit, DebateSide side) {
    // Whether the local user (current main speaker in test mode) can answer POIs.
    final canAnswer = cubit.currentSlot != null;
    return Column(
      children: [
        for (var i = 0; i < cubit.teamFor(side).debaters.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Expanded(
            child: Builder(builder: (context) {
              final debater = cubit.debaterAt(side, i);
              final asking = cubit.isAskingPOIByDebater(debater.id);
              return SpeakerCard(
                debater: debater,
                side: side,
                roleLabel: cubit.roleLabel(side, i),
                isCurrentSpeaker: cubit.isCurrentSpeaker(side, i),
                isAskingPoi: asking,
                canModerate: canModerate,
                onPoiTap: (asking && canAnswer)
                    ? () => _showAcceptRefuse(context, cubit)
                    : null,
              );
            }),
          ),
        ],
      ],
    );
  }

  void _showAcceptRefuse(BuildContext context, DebateCubit cubit) {
    final loc = context.loc;
    final askerSid = cubit.localParticipant?.sid ?? 'local';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.poiTitle, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(loc.poiPrompt, style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () {
              cubit.refusePOI(askerSid);
              Navigator.of(context).maybePop();
            },
            child: Text(loc.refuse, style: const TextStyle(color: JadalColors.judgesGrey)),
          ),
          TextButton(
            onPressed: () {
              cubit.acceptPOI(askerSid);
              Navigator.of(context).maybePop();
            },
            child: Text(loc.accept,
                style: const TextStyle(color: JadalColors.primaryBlue, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
