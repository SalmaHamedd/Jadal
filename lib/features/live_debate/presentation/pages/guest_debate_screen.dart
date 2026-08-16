import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_text.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../cubits/connection_cubit.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_access.dart';
import '../utils/debate_theme.dart';
import 'debate_room_screen.dart';

/// Entry point for a share link opened without an account.
/// Loads the debate's public state, then drops straight into the main room —
/// guests never see the lobby, since every other room is closed to them.
class GuestDebateScreen extends StatelessWidget {
  final int debateId;
  const GuestDebateScreen({super.key, required this.debateId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              di.sl<DebateController>(param1: debateId, param2: true)..init(),
        ),
        BlocProvider(create: (_) => di.sl<ConnectionCubit>()),
      ],
      child: const _GuestGate(),
    );
  }
}

/// Holds the guest on a loader until the public state arrives, and shows a
/// dead-end message if the link's viewing window has closed.
class _GuestGate extends StatelessWidget {
  const _GuestGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebateController, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateController>();
        final failure = cubit.loadFailure;
        if (failure != null && !cubit.isReady) {
          return _LinkUnavailableView(failure: failure);
        }
        if (!cubit.isReady) return const _LoadingView();
        return const DebateRoomScreen(role: LiveJoinRole.audience);
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      body: JadalGradientBackground(
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// Shown when the backend closes guest access — the debate hasn't started yet,
/// or it ended more than ten minutes ago. Deliberately offers no sign-in
/// prompt: this is not an authentication problem.
class _LinkUnavailableView extends StatelessWidget {
  final Failure failure;
  const _LinkUnavailableView({required this.failure});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isClosedLink = failure is GoneFailure;
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      body: JadalGradientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isClosedLink
                        ? Icons.link_off_rounded
                        : Icons.error_outline_rounded,
                    size: 56,
                    color: DebateTheme.textSecondary(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isClosedLink ? loc.guestLinkUnavailableTitle : loc.errorGeneric,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title(context)
                        .copyWith(color: DebateTheme.textPrimary(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FailureText.of(context, failure),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context)
                        .copyWith(color: DebateTheme.textSecondary(context)),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: () {
                      final nav = Navigator.of(context);
                      if (nav.canPop()) nav.pop();
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(loc.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
