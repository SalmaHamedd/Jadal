import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';
import 'jadal_video_card.dart';
import 'participant_details_dialog.dart';

/// A tile to render in the grid layout.
class GridParticipant {
  final String id;
  final String name;
  final bool isLocal;
  const GridParticipant({required this.id, required this.name, this.isLocal = false});
}

/// Layout 1 — the Google-Meet-style responsive grid. Used in prep/result
/// rooms and as the open-lobby mode of the live debate. Everyone (participants
/// + audience) renders as the same [JadalVideoCard].
class GridLayout extends StatelessWidget {
  final List<GridParticipant> participants;
  const GridLayout({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.isMobile ? 2 : (context.isTablet ? 3 : 4);
    return BlocBuilder<DebateController, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateController>();
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: participants.length,
          itemBuilder: (context, i) {
            final p = participants[i];
            final dark = DebateTheme.isDark(context);
            const outer = widgetBorderRadius + 2;
            const bw = 2.5;
            // Border must read as distinct from the card body in BOTH themes
            // (dark's elevated surface used to match the card exactly).
            final cardBorder = dark
                ? Color.lerp(JadalColors.darkSurfaceElevated, Colors.white, 0.14)!
                : DebateTheme.surfaceElevated(context);
            return SelectableCard(
              participantId: p.id,
              onShowDetails: () => showParticipantDetails(
                context,
                cubit,
                participantId: p.id,
                name: p.name,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(outer),
                  border: Border.all(color: cardBorder, width: bw),
                ),
                // Inner radius = outer − border so no sliver of background shows
                // at the rounded corners.
                child: JadalVideoCard(
                  name: p.name,
                  participantId: p.id,
                  avatarUrl: cubit.avatarUrlForUser(p.id),
                  bgColor: DebateTheme.floatingCard(context),
                  // Wire each tile to its OWN media (local or a present remote),
                  // so remote cameras show and we never paint the local stream on
                  // someone else's tile.
                  showVideo: cubit.showVideoForUser(p.id),
                  videoTrack: cubit.videoTrackForUser(p.id),
                  isMicEnabled: cubit.micOnForUser(p.id),
                  isSpeaking: cubit.speakingForUser(p.id),
                  micLevel: cubit.isLocalUserId(p.id) ? () => cubit.localAudioLevel : null,
                  mainAxis: 168,
                  borderRadius: outer - bw,
                  nameColor: DebateTheme.textPrimary(context),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
