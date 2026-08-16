import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/debate_models.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import 'participant_details_dialog.dart';
import 'speaker_card.dart';

/// Speakers-section layout: two side columns of speaker cards with a
/// narrow central channel that holds the POI pill. Flex weights sum to 100
/// (38 / 24 / 38) so the teams sit either side of a clear middle gap.
const int kSpeakerColumnFlex = 38;
const int kSpeakerGapFlex = 24;

/// Speakers section: 3 proposition cards on the left (blue), 3
/// opposition cards on the right (orange), with a central POI channel between
/// them. Each card is wrapped in a [SelectableCard] so a tap reveals its 3-dots
/// → participant details.
class SpeakersSection extends StatelessWidget {
  const SpeakersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebateController, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateController>();
        // The sides are FIXED regardless of the app locale (incl. Arabic RTL):
        // **opposition on the LEFT, proposition on the RIGHT.** Forcing LTR on this
        // row keeps that order; the per-card POI badge still anchors to the outer edge.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: kSpeakerColumnFlex,
                child: _column(context, cubit, DebateSide.opposition),
              ),
              // POIs render as a badge anchored to the asking debater's own
              // card (see SpeakerCard); the old centered pill is gone — this is the gap.
              const Expanded(flex: kSpeakerGapFlex, child: SizedBox.shrink()),
              Expanded(
                flex: kSpeakerColumnFlex,
                child: _column(context, cubit, DebateSide.proposition),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _column(BuildContext context, DebateController cubit, DebateSide side) {
    // ONLY the current main speaker may accept/answer a POI — not every
    // device that happens to see the raised-hand badge.
    final canAnswer = cubit.iAmCurrentSpeaker;
    // Render a FIXED N slots per side (= speakers per side) so both columns
    // are equal height; a side with fewer speakers leaves its bottom slot(s) as a
    // quiet "not joined" placeholder rather than stretching its cards.
    final count = cubit.speakersPerSide;
    final order = cubit.orderFor(side);
    final slot = cubit.currentSlot;
    // The id currently featured in the MAIN speaker card — its video lives there,
    // so we never also render it in a side card (video shown once).
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
                  micOn: present && cubit.micOnForUser(debater.id),
                  isSpeaking: present && cubit.speakingForUser(debater.id),
                  levelProvider: cubit.isLocalUserId(debater.id)
                      ? () => cubit.localAudioLevel
                      : null,
                  onPoiTap: (asking && canAnswer)
                      ? () => showPoiAcceptRefuse(context, cubit, askerUserId: debater.id)
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

/// The speaker's accept/refuse prompt for an incoming POI. [askerUserId]
/// is the debater whose card was tapped, so accepting/refusing targets that
/// SPECIFIC asker — letting the speaker answer the 2nd asker, not the 1st.
void showPoiAcceptRefuse(BuildContext context, DebateController cubit,
    {String? askerUserId}) {
  final loc = context.loc;
  final asker = askerUserId ?? cubit.localParticipant?.sid ?? 'local';
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: DebateTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(loc.poiTitle, style: AppTextStyles.title(context)),
      content: Text(loc.poiPrompt, style: AppTextStyles.body(context)),
      actions: [
        TextButton(
          onPressed: () {
            cubit.refusePOI(asker);
            Navigator.of(context).maybePop();
          },
          child: Text(loc.refuse,
              style: AppTextStyles.button(context).copyWith(color: JadalColors.judgesGrey)),
        ),
        TextButton(
          onPressed: () {
            cubit.acceptPOI(asker);
            Navigator.of(context).maybePop();
          },
          child: Text(loc.accept,
              style: AppTextStyles.button(context)
                  .copyWith(color: JadalColors.primaryBlue, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
