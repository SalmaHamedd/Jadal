import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';
import 'jadal_video_card.dart';

/// A tile to render in the grid layout.
class GridParticipant {
  final String id;
  final String name;
  final bool isLocal;
  const GridParticipant({required this.id, required this.name, this.isLocal = false});
}

/// Layout 1 — the Google-Meet-style responsive grid (§8.2). Used in prep/result
/// rooms and as the open-lobby mode of the live debate. Everyone (participants
/// + audience) renders as the same [JadalVideoCard].
class GridLayout extends StatelessWidget {
  final List<GridParticipant> participants;
  const GridLayout({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.isMobile ? 2 : (context.isTablet ? 3 : 4);
    return BlocBuilder<DebateCubit, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateCubit>();
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
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widgetBorderRadius + 2),
                border: Border.all(
                  color: DebateTheme.surfaceElevated(context),
                  width: 3,
                ),
              ),
              child: JadalVideoCard(
                name: p.name,
                participantId: p.id,
                bgColor: DebateTheme.floatingCard(context),
                showVideo: p.isLocal && cubit.isCameraEnabled,
                videoTrack: p.isLocal ? cubit.localVideoTrack : null,
                isMicEnabled: p.isLocal ? cubit.isMicEnabled : false,
                isSpeaking: p.isLocal ? cubit.isLocalSpeaking : false,
                mainAxis: 168,
              ),
            );
          },
        );
      },
    );
  }
}
