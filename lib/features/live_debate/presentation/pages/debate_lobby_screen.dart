import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../core/widgets/jadal_gradient_button.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/models/debate_models.dart';
import '../../domain/debate_room_role.dart';
import '../cubits/connection_cubit.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_access.dart';
import '../utils/debate_theme.dart';
import '../widgets/debate_screen_header.dart';
import 'debate_room_screen.dart';
import 'prep_room_screen.dart';
import 'result_room_screen.dart';

/// Lobby / rooms list (§8.1). The entry point of the feature — provides the
/// shared [DebateController] + [ConnectionCubit] that persist across the room
/// screens, and gates each room with the [DebateAccess] rules.
///
/// [debateId] picks which backend debate to load (from the list → detail flow,
/// §13); null falls back to `DebateModeConfig.devDebateId`. Ignored in test mode.
class DebateLobbyScreen extends StatelessWidget {
  final int? debateId;
  const DebateLobbyScreen({super.key, this.debateId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // init() loads profile + live-state in backend mode; no-op in test mode.
        BlocProvider(create: (_) => di.sl<DebateController>(param1: debateId)..init()),
        BlocProvider(create: (_) => di.sl<ConnectionCubit>()),
      ],
      child: const _LobbyView(),
    );
  }
}

class _LobbyView extends StatelessWidget {
  const _LobbyView();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateController>();

    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      body: JadalGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              DebateScreenHeader(title: loc.lobbyTitle),
              Expanded(
                child: BlocBuilder<DebateController, DebateStates>(
                  builder: (context, state) {
                    // Backend mode shows a loader until live-state arrives.
                    if (!cubit.isReady) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = cubit.data;
                    // After the chair closes the room with an unshared result,
                    // only the chair sees a "share result" action here → flips the
                    // debate to done (§U4b).
                    final showShare = cubit.canManageResult &&
                        cubit.isRoomClosed &&
                        cubit.resultView != null &&
                        !cubit.resultShared;
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (showShare)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ShareResultBanner(cubit: cubit),
                          ),
                        for (final room in data.rooms)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _RoomCard(room: room),
                          ),
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

class _RoomCard extends StatelessWidget {
  final DebateRoom room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateController>();
    final access = _evaluate(context, cubit);
    // "on" = the room is joinable now; "off" = locked (lighter colours).
    final on = !access.locked;
    final isLive = room.type == DebateRoomType.liveDebate;

    final icon = switch (room.type) {
      DebateRoomType.proposition => Icons.shield_rounded,
      DebateRoomType.opposition => Icons.gavel_rounded,
      DebateRoomType.liveDebate => Icons.podcasts_rounded,
      DebateRoomType.result => Icons.emoji_events_rounded,
    };

    // Card border/accent per room + state (§U3). Live is the meeting point of
    // both brand colours, so it gets the blue↔orange gradient treatment.
    final lightOrange = _lighten(JadalColors.primaryOrange, 0.45);
    final lightBlue = _lighten(JadalColors.primaryBlue, 0.45);
    final accent = switch (room.type) {
      DebateRoomType.proposition =>
        on ? JadalColors.primaryBlue : _lighten(JadalColors.primaryBlue, 0.4),
      DebateRoomType.opposition =>
        on ? JadalColors.primaryOrange : _lighten(JadalColors.primaryOrange, 0.4),
      DebateRoomType.liveDebate => on ? JadalColors.deepBlue : JadalColors.judgesGrey,
      DebateRoomType.result => JadalColors.judgesGrey,
    };

    final iconWidget = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isLive ? null : accent.withValues(alpha: 0.14),
        gradient: isLive
            ? LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [lightOrange, lightBlue],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: isLive ? JadalColors.deepBlue : accent),
    );

    final inner = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DebateTheme.surface(context),
        borderRadius: BorderRadius.circular(isLive ? 18 : 20),
        // Live uses the surrounding gradient ring instead of a flat border.
        border: isLive ? null : Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: isLive
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(loc),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle(context)
                      .copyWith(color: DebateTheme.textPrimary(context)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(access.locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 13, color: DebateTheme.textSecondary(context)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        access.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small(context)
                            .copyWith(color: DebateTheme.textSecondary(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _RoomJoinButton(type: room.type, enabled: on, onPressed: access.onJoin),
        ],
      ),
    );

    if (!isLive) return inner;

    // Live debate: blue↔orange gradient border + a blended glow elevation.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [lightOrange, lightBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: JadalColors.primaryOrange.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: JadalColors.primaryBlue.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.6),
      child: inner,
    );
  }

  /// Lighten a colour toward white by [amount] (0..1).
  static Color _lighten(Color c, double amount) => Color.lerp(c, Colors.white, amount)!;

  String _title(AppLocalizations loc) {
    switch (room.type) {
      case DebateRoomType.proposition:
        return '${loc.proposition} (${room.team?.teamName ?? ''})';
      case DebateRoomType.opposition:
        return '${loc.opposition} (${room.team?.teamName ?? ''})';
      case DebateRoomType.liveDebate:
        return loc.liveDebateRoom;
      case DebateRoomType.result:
        return loc.resultRoomTitle;
    }
  }

  _RoomAccess _evaluate(BuildContext context, DebateController cubit) {
    final loc = context.loc;
    // Backend mode gates pre-join from live-state (joinable_for_me); test mode
    // returns null here and uses the local DebateAccess rules below.
    final gate = cubit.backendRoomGate(room.type);
    if (gate != null) return _backendAccess(context, cubit, gate);

    final data = cubit.data;
    final userId = data.currentUserId;
    final now = DateTime.now();

    switch (room.type) {
      case DebateRoomType.proposition:
      case DebateRoomType.opposition:
        final team = room.team!;
        if (!DebateAccess.canJoinTeamRoom(team, userId)) {
          return _RoomAccess(status: loc.onlyTeamMembers, locked: true, onJoin: null);
        }
        final open = DebateAccess.prepOpen(data.format, data.debateStartTime, now);
        if (!open) {
          return _RoomAccess(status: loc.prepClosed, locked: true, onJoin: null);
        }
        return _RoomAccess(
          status: loc.statusOpen,
          locked: false,
          onJoin: () => _push(context, cubit, PrepRoomScreen(side: team.side)),
        );

      case DebateRoomType.liveDebate:
        // The chair closed the room → join is locked for everyone (§U4b).
        if (cubit.isRoomClosed) {
          return _RoomAccess(status: loc.roomClosedStatus, locked: true, onJoin: null);
        }
        final role = DebateAccess.resolveLiveJoinRole(
          judgeIds: room.judgeIds,
          propTeam: data.propositionTeam,
          oppTeam: data.oppositionTeam,
          propOrder: cubit.propOrder,
          oppOrder: cubit.oppOrder,
          userId: userId,
        );
        if (role == LiveJoinRole.blockedNeedsOrder) {
          return _RoomAccess(
            status: loc.orderNotSet,
            locked: true,
            onJoin: () => _showNeedsOrder(context, cubit),
          );
        }
        return _RoomAccess(
          status: loc.statusOpen,
          locked: false,
          onJoin: () => _pushRoom(context, cubit, role),
        );

      case DebateRoomType.result:
        if (!DebateAccess.resultRoomOpen(cubit.debateFinished)) {
          return _RoomAccess(status: loc.resultsNotReady, locked: true, onJoin: null);
        }
        // Judges-only is enforced here; in test the user may not be a judge, so
        // we allow viewing the finished results screen.
        // TODO(role-gating): restrict to judges present at finish.
        return _RoomAccess(
          status: loc.statusOpen,
          locked: false,
          onJoin: () => _push(context, cubit, const ResultRoomScreen()),
        );
    }
  }

  /// Backend pre-join gate (§7): joinability comes from `live-state.rooms`.
  _RoomAccess _backendAccess(
    BuildContext context,
    DebateController cubit,
    ({bool joinable, DebateRoomRole? role}) gate,
  ) {
    final loc = context.loc;
    if (!gate.joinable) {
      final status = switch (room.type) {
        DebateRoomType.proposition || DebateRoomType.opposition => loc.onlyTeamMembers,
        DebateRoomType.result => loc.resultsNotReady,
        DebateRoomType.liveDebate => loc.orderNotSet,
      };
      return _RoomAccess(status: status, locked: true, onJoin: null);
    }
    return _RoomAccess(
      status: loc.statusOpen,
      locked: false,
      onJoin: () => _joinBackend(context, cubit),
    );
  }

  /// Fetches the room-scoped token (token discipline, §7) and navigates. The
  /// live room connects inside [DebateRoomScreen.enterDebateRoom], so it isn't
  /// pre-joined here.
  Future<void> _joinBackend(BuildContext context, DebateController cubit) async {
    switch (room.type) {
      case DebateRoomType.liveDebate:
        _pushRoom(context, cubit, LiveJoinRole.participant);
      case DebateRoomType.proposition:
      case DebateRoomType.opposition:
        await cubit.joinRoom(room.type);
        if (context.mounted) _push(context, cubit, PrepRoomScreen(side: room.team!.side));
      case DebateRoomType.result:
        await cubit.joinRoom(room.type);
        if (context.mounted) _push(context, cubit, const ResultRoomScreen());
    }
  }

  Future<void> _showNeedsOrder(BuildContext context, DebateController cubit) {
    final loc = context.loc;
    final data = cubit.data;
    final side = data.propositionTeam.debaterById(data.currentUserId) != null
        ? DebateSide.proposition
        : DebateSide.opposition;
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DebateTheme.surface(context),
        title: Text(loc.needOrderTitle, style: AppTextStyles.title(context)),
        content: Text(loc.needOrderBody, style: AppTextStyles.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).maybePop();
              _push(context, cubit, PrepRoomScreen(side: side));
            },
            child: Text(loc.goToPrep),
          ),
        ],
      ),
    );
  }

  Future<void> _push(BuildContext context, DebateController cubit, Widget screen) {
    // Carry the ConnectionCubit so prep/result rooms get the action row too (§9.3).
    final connection = context.read<ConnectionCubit>();
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: connection),
        ],
        child: screen,
      ),
    ));
  }

  Future<void> _pushRoom(BuildContext context, DebateController cubit, LiveJoinRole role) {
    final connection = context.read<ConnectionCubit>();
    if (role == LiveJoinRole.audience) {
      JadalSnackBar.show(context, context.loc.joiningAsAudience, type: SnackBarType.success);
    }
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: connection),
        ],
        child: DebateRoomScreen(role: role),
      ),
    ));
  }
}

class _RoomAccess {
  final String status;
  final bool locked;

  /// Async so the join button can show a spinner and block re-taps while the
  /// room-token fetch / navigation is in flight (prevents entering twice on lag).
  final Future<void> Function()? onJoin;
  const _RoomAccess({required this.status, required this.locked, required this.onJoin});
}

/// Chair-only rooms-list action shown after the room is closed with an unshared
/// result: shares it (flips the debate live→done) without navigating (§U4b).
class _ShareResultBanner extends StatelessWidget {
  final DebateController cubit;
  const _ShareResultBanner({required this.cubit});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DebateTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JadalColors.primaryOrange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.shareResultPrompt,
              style: AppTextStyles.bodyEmphasis(context)
                  .copyWith(color: DebateTheme.textPrimary(context))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: JadalGradientButton(
              text: loc.shareResult,
              icon: Icons.emoji_events_rounded,
              onPressed: () async {
                await cubit.shareResult();
                if (context.mounted) {
                  JadalSnackBar.show(context, loc.resultSharedMsg, type: SnackBarType.success);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact per-room join button (§U3): solid side colour for prop/opp (light
/// when locked, main when joinable); the blue↔orange gradient for the live room
/// and result (grey when locked).
///
/// Stateful so it can show a spinner and swallow further taps while the join is
/// in flight — a laggy room-token fetch used to let an impatient user tap several
/// times and get pushed into the room more than once.
class _RoomJoinButton extends StatefulWidget {
  final DebateRoomType type;
  final bool enabled;
  final Future<void> Function()? onPressed;
  const _RoomJoinButton({required this.type, required this.enabled, required this.onPressed});

  @override
  State<_RoomJoinButton> createState() => _RoomJoinButtonState();
}

class _RoomJoinButtonState extends State<_RoomJoinButton> {
  static const double _w = 82;
  static const double _h = 36;
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy || widget.onPressed == null) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final gradient =
        widget.type == DebateRoomType.liveDebate || widget.type == DebateRoomType.result;

    final Color fill = switch (widget.type) {
      DebateRoomType.proposition => widget.enabled
          ? JadalColors.primaryBlue
          : Color.lerp(JadalColors.primaryBlue, Colors.white, 0.55)!,
      DebateRoomType.opposition => widget.enabled
          ? JadalColors.primaryOrange
          : Color.lerp(JadalColors.primaryOrange, Colors.white, 0.55)!,
      // Live / result locked → light grey.
      _ => Color.lerp(JadalColors.judgesGrey, Colors.white, 0.35)!,
    };

    // While joining, show a spinner chip in place of the button (same footprint)
    // so the layout never jumps and the tap can't be repeated.
    if (_busy) {
      return Container(
        width: _w,
        height: _h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient
              ? const LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [JadalColors.primaryOrange, JadalColors.primaryBlue],
                )
              : null,
          color: gradient ? null : fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      );
    }

    if (gradient && widget.enabled) {
      return SizedBox(
        width: _w,
        child: JadalGradientButton(text: loc.join, height: _h, onPressed: _handle),
      );
    }

    return GestureDetector(
      onTap: widget.enabled ? _handle : null,
      child: Container(
        width: _w,
        height: _h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          loc.join,
          style: AppTextStyles.button(context).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
