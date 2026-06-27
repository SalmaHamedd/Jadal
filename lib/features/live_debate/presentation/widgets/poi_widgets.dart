import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_gradient_button.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';

/// Shown to the asker after the speaker accepts their POI (§8.4): a mic control
/// + a Done button that returns them to silence.
class PoiAskerMicDialog extends StatelessWidget {
  const PoiAskerMicDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return BlocBuilder<DebateController, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateController>();
        return AlertDialog(
          backgroundColor: DebateTheme.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            loc.poiYourTurn,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: DebateTheme.textPrimary(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.poiSpeakNow,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', color: DebateTheme.textSecondary(context)),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: cubit.toggleMic,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: cubit.isMicEnabled
                      ? JadalColors.primaryBlue.withValues(alpha: 0.18)
                      : JadalColors.judgesGrey.withValues(alpha: 0.18),
                  child: Icon(
                    cubit.isMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                    size: 32,
                    color: cubit.isMicEnabled
                        ? JadalColors.primaryBlue
                        : JadalColors.judgesGrey,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            JadalGradientButton(
              text: loc.poiDone,
              width: 140,
              onPressed: () {
                cubit.poiDone();
                Navigator.of(context).maybePop();
              },
            ),
          ],
        );
      },
    );
  }
}
