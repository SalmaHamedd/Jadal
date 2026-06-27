import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/debate_models.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import 'participant_details_dialog.dart';
import 'speaker_card.dart';

/// Speakers-section layout (§11): two side columns of speaker cards with a
/// narrow central channel that holds the POI pill. Flex weights sum to 100
/// (38 / 24 / 38) so the teams sit either side of a clear middle gap.
const int kSpeakerColumnFlex = 38;
const int kSpeakerGapFlex = 24;

/// Speakers section (§8.3 C): 3 proposition cards on the left (blue), 3
/// opposition cards on the right (orange), with a central POI channel between
/// them. Each card is wrapped in a [SelectableCard] so a tap reveals its 3-dots
/// → participant details (§9.2).
class SpeakersSection extends StatelessWidget {
  const SpeakersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebateController, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateController>();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: kSpeakerColumnFlex,
              child: _column(context, cubit, DebateSide.proposition),
            ),
            Expanded(flex: kSpeakerGapFlex, child: _PoiChannel(cubit: cubit)),
            Expanded(
              flex: kSpeakerColumnFlex,
              child: _column(context, cubit, DebateSide.opposition),
            ),
          ],
        );
      },
    );
  }

  Widget _column(BuildContext context, DebateController cubit, DebateSide side) {
    // Whether the local user (current main speaker in test mode) can answer POIs.
    final canAnswer = cubit.currentSlot != null;
    final count = cubit.teamFor(side).debaters.length;
    final order = cubit.orderFor(side);
    final slot = cubit.currentSlot;
    // The id currently featured in the MAIN speaker card — its video lives there,
    // so we never also render it in a side card (video shown once, §multi-role).
    final currentMainId =
        slot == null ? null : cubit.debaterAt(slot.side, slot.orderIndex).id;

    // The slot indices a given debater occupies on this side (>1 ⇒ multi-role).
    List<int> slotsOf(String id) {
      final out = <int>[];
      for (var j = 0; j < count; j++) {
        if (cubit.debaterAt(side, j).id == id) out.add(j);
      }
      return out;
    }

    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Expanded(
            child: Builder(builder: (context) {
              final debater = cubit.debaterAt(side, i);
              final occupied = slotsOf(debater.id);
              // A debater can fill several slots (rare). Only their CURRENT slot
              // (if speaking) else their first slot "owns" them — the others act as
              // "hasn't joined yet", so the person + their video appear only once.
              final isMine = currentMainId == debater.id &&
                  slot != null &&
                  slot.side == side;
              final primary = isMine ? slot.orderIndex : occupied.first;
              final isPrimary = i == primary;

              final present = isPrimary && cubit.isUserPresent(debater.id);
              final asking = isPrimary && cubit.isAskingPOIByDebater(debater.id);
              // Combined label on the owning slot when multi-role (e.g. "P1-P3-PR").
              final label = isPrimary && occupied.length > 1
                  ? _combinedLabel(side, occupied, order.replySpeakerId == debater.id)
                  : cubit.roleLabel(side, i);
              // Video only once: in a side card only when this debater is NOT the
              // one featured in the main card.
              final showVid = present &&
                  debater.id != currentMainId &&
                  cubit.showVideoForUser(debater.id);

              return SelectableCard(
                participantId: debater.id,
                // Live cards keep the name bottom-start, so the dots go bottom-end.
                dotsCorner: CardDotsCorner.bottomEnd,
                onShowDetails: () => showParticipantDetails(
                  context,
                  cubit,
                  participantId: debater.id,
                  name: debater.name,
                ),
                child: SpeakerCard(
                  debater: debater,
                  side: side,
                  roleLabel: label,
                  isCurrentSpeaker: cubit.isCurrentSpeaker(side, i),
                  isAskingPoi: asking,
                  isPresent: present,
                  showVideo: showVid,
                  videoTrack: present ? cubit.videoTrackForUser(debater.id) : null,
                  onPoiTap: (asking && canAnswer)
                      ? () => showPoiAcceptRefuse(context, cubit)
                      : null,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  /// A multi-role label like `P1-P3` (+ `-PR` when this speaker also replies).
  String _combinedLabel(DebateSide side, List<int> occupied, bool isReply) {
    final base = occupied.map((j) => '${side.rolePrefix}${j + 1}').join('-');
    return isReply ? '$base-${side.replySuffix}' : base;
  }
}

/// The central 24% channel between the teams (§11). Shows a POI pill — coloured
/// by the asking (opposing) side — whenever a POI is in flight; tapping it lets
/// the current speaker accept/refuse (the per-card bubble is the other entry).
class _PoiChannel extends StatelessWidget {
  final DebateController cubit;
  const _PoiChannel({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final slot = cubit.currentSlot;
    final asking = slot != null && (cubit.askingPoiSids.isNotEmpty || cubit.isLocalAskingPOI);
    if (!asking) return const SizedBox.shrink();

    final askingSide = slot.side.other;
    final color = DebateTheme.sideColor(askingSide);

    return Center(
      child: GestureDetector(
        onTap: () => showPoiAcceptRefuse(context, cubit),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1.4),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.front_hand_rounded, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                loc.poiTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  height: 1.1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The speaker's accept/refuse prompt for an incoming POI (§8.4).
void showPoiAcceptRefuse(BuildContext context, DebateController cubit) {
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
