import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either;

import '../../../../core/error/failures.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/models/debate_models.dart';
import '../../data/models/live_state_model.dart';
import '../../data/models/registration_models.dart';
import '../../data/repositories/live_debate_repository.dart';
import '../../domain/debate_result_view.dart';
import '../../domain/debate_status.dart';
import '../utils/debate_date.dart';
import '../utils/debate_log.dart';
import '../utils/debate_theme.dart';
import '../widgets/debate_screen_header.dart';
import '../widgets/registration_sheet.dart';
import '../widgets/result_summary_view.dart';
import 'debate_lobby_screen.dart';
import '../../../complaints/data/repositories/complaint_repository_impl.dart';
import '../../../complaints/presentation/screens/create_complaint_screen.dart';

/// Debate detail via `GET /live-state` (§13): motion (coloured framework chips +
/// tags), judges, prop/opp speakers with their order + reply, the stages, and —
/// for a completed debate — the shared [ResultSummaryView]. The CTA is
/// status-aware: register (pre-live), join (live), or nothing (done/cancelled).
class BackendDebateDetailScreen extends StatefulWidget {
  final int debateId;
  final String? title;
  const BackendDebateDetailScreen({
    super.key,
    required this.debateId,
    this.title,
  });

  @override
  State<BackendDebateDetailScreen> createState() =>
      _BackendDebateDetailScreenState();
}

class _BackendDebateDetailScreenState extends State<BackendDebateDetailScreen> {
  late Future<Either<Failure, LiveStateModel>> _future;

  @override
  void initState() {
    super.initState();
    // Open the on-device trace file (and print its path) the moment the user
    // lands on debate-details — this is the start of the flow we want captured.
    dlogInitFile();
    dlog(
      'details',
      '▶ OPEN debate-details (debateId=${widget.debateId}, '
          'title="${widget.title ?? ''}")',
    );
    _future = _loadLiveState('open details');
  }

  void _reload() {
    setState(() => _future = _loadLiveState('retry/reload details'));
  }

  /// Fetch the details' live-state. The FULL raw response body is logged by the
  /// repository (`http` tag); this adds a screen-level marker + a one-line digest
  /// so the trace clearly shows the user opened details and how it resolved.
  Future<Either<Failure, LiveStateModel>> _loadLiveState(String reason) {
    dlog(
      'details',
      'GET live-state for details — reason="$reason" '
          'debateId=${widget.debateId}',
    );
    final future = di.sl<LiveDebateRepository>().getLiveState(widget.debateId);
    future.then(
      (res) => res.fold(
        (f) => dlog('details', '✗ details live-state FAILED: ${f.message}'),
        (s) => dlog(
          'details',
          '✓ details live-state OK — status=${s.debate.statusRaw} '
              'currentStage=${s.debate.currentStage} judges=${s.judges.length} '
              'prop.speakers=${s.proposition.speakers.length} '
              'opp.speakers=${s.opposition.speakers.length} stages=${s.stages.length}',
        ),
      ),
    );
    return future;
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      backgroundColor: DebateTheme.background(context),
      // No AppBar — the gradient runs edge-to-edge and the title lives in an
      // in-body header over it.
      body: JadalGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              DebateScreenHeader(
                title: widget.title ?? loc.debatesTitle,
                actions: [
                  IconButton(
                    tooltip: loc.submitComplaintTooltip,
                    icon: const Icon(Icons.report_gmailerrorred_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateComplaintScreen(
                          repository: ComplaintRepositoryImpl(),
                          initialDebateId: widget.debateId,
                          initialDebateTitle: widget.title ?? loc.debatesTitle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<Either<Failure, LiveStateModel>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return snap.data!.fold(
                      (f) => _ErrorView(message: f.message, onRetry: _reload),
                      (state) => _content(context, state),
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

  Widget _content(BuildContext context, LiveStateModel state) {
    final loc = context.loc;
    final motion = state.motion;
    final status = state.debate.status;

    // Per-status visibility (§U2):
    //  • registration (scheduled) → format only; no motion/teams/judges yet.
    //  • announced → + judges + teams shown neutrally (first/second, sides TBD);
    //    motion only once its reveal time has passed.
    //  • sides-selected/live/done/cancelled → sides fixed (prop/opp); motion shown.
    final isRegistration = status == DebateStatus.scheduled;
    final isAnnounced = status == DebateStatus.announced;
    final sidesKnown =
        status == DebateStatus.teamsSelected ||
        status == DebateStatus.live ||
        status == DebateStatus.completed ||
        status == DebateStatus.cancelled;
    final motionRevealed =
        motion != null &&
        motion.text.isNotEmpty &&
        (sidesKnown ||
            (state.debate.motionRevealedAt != null &&
                state.debate.motionRevealedAt!.isBefore(DateTime.now())));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (state.debate.isCancelled &&
            (state.debate.cancellationReason?.isNotEmpty ?? false))
          _Banner(
            icon: Icons.cancel_rounded,
            color: const Color(0xFFE53935),
            text:
                '${loc.cancellationReasonLabel}: ${state.debate.cancellationReason}',
          ),
        // Vibrant gradient hero — status + title + (once revealed) the motion,
        // with its frameworks/tags as small chips inside the hero itself (the old
        // separate "motion" section that only repeated them is gone).
        _HeroHeader(
          title: widget.title ?? state.debate.title,
          statusLabel: _statusLabel(loc, status),
          statusColor: _statusAccent(status),
          motionText: motionRevealed ? motion.text : null,
          frameworkNames: motionRevealed
              ? motion.frameworks.map((f) => f.name).toList()
              : const [],
          tags: motionRevealed ? motion.tags : const [],
        ),
        // Format — always available.
        _Section(
          title: loc.formatLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.format.name ?? '—',
                style: AppTextStyles.subtitle(
                  context,
                ).copyWith(color: DebateTheme.textPrimary(context)),
              ),
              if (state.format.speakersPerSide != null)
                _kv(
                  context,
                  loc.speakersPerSideLabel,
                  '${state.format.speakersPerSide}',
                ),
              if (state.debate.scheduledAt != null)
                _kv(
                  context,
                  loc.scheduledLabel,
                  formatDebateDate(state.debate.scheduledAt),
                ),
            ],
          ),
        ),
        // While registration is open, surface who's registered so far (V12 §3).
        if (isRegistration) _RegistrantsBar(debateId: widget.debateId),
        // Judges + teams — nothing to show during registration.
        if (!isRegistration) ...[
          // Judges sit in the same calm section card as Format (the user didn't
          // want the old busy strip), with the chair keeping its star/ring badge.
          if (state.judges.isNotEmpty)
            _Section(
              title: loc.judgesLabel,
              child: _JudgesContent(judges: state.judges),
            ),
          // Teams sit side-by-side as two filled, team-coloured panels (§design).
          _teamsRow(context, state, neutral: isAnnounced),
        ],
        // Result (completed debates) — the shared widget, winner detail-only (§13).
        if (state.debate.isCompleted) ...[
          const SizedBox(height: 4),
          _Section(
            title: loc.results,
            child: ResultSummaryView(
              result: DebateResultView.fromLiveState(state),
              shrinkWrap: true,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _cta(context, state),
      ],
    );
  }

  /// The two teams as side-by-side, filled team-coloured panels. During the
  /// announced stage sides aren't fixed yet → both render neutral (first/second).
  Widget _teamsRow(
    BuildContext context,
    LiveStateModel state, {
    required bool neutral,
  }) {
    final loc = context.loc;
    // Neutral (announced) cards use a muted slate instead of the old flat grey:
    // a deep blue-grey that reads as a calm, sides-not-set tint and blends into
    // both the light and dark backgrounds (white header text stays readable).
    const neutralTeam = Color(0xFF44546E);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _TeamColumn(
                title: neutral ? loc.firstTeam : loc.proposition,
                info: state.proposition,
                color: neutral
                    ? neutralTeam
                    : DebateTheme.sideColor(DebateSide.proposition),
                neutral: neutral,
                showOrder: !neutral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TeamColumn(
                title: neutral ? loc.secondTeam : loc.opposition,
                info: state.opposition,
                color: neutral
                    ? neutralTeam
                    : DebateTheme.sideColor(DebateSide.opposition),
                neutral: neutral,
                showOrder: !neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cta(BuildContext context, LiveStateModel state) {
    final loc = context.loc;
    switch (state.debate.status) {
      case DebateStatus.live:
        return _PrimaryButton(
          label: loc.joinNow,
          icon: Icons.podcasts_rounded,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DebateLobbyScreen(debateId: widget.debateId),
            ),
          ),
        );
      case DebateStatus.scheduled:
        // Registration is only open while scheduled (the API 422s otherwise).
        return _PrimaryButton(
          label: loc.register,
          icon: Icons.how_to_reg_rounded,
          onPressed: () async {
            final ok = await showRegistrationSheet(context, widget.debateId);
            if (ok == true && mounted) _reload();
          },
        );
      case DebateStatus.announced:
      case DebateStatus.teamsSelected:
      case DebateStatus.completed:
      case DebateStatus.cancelled:
      case DebateStatus.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      '$k: $v',
      style: AppTextStyles.body(
        context,
      ).copyWith(color: DebateTheme.textSecondary(context)),
    ),
  );
}

String _statusLabel(AppLocalizations loc, DebateStatus s) => switch (s) {
  DebateStatus.scheduled => loc.tabRegistration,
  DebateStatus.announced => loc.tabAnnounced,
  DebateStatus.teamsSelected => loc.tabSidesSelected,
  DebateStatus.live => loc.tabLive,
  DebateStatus.completed => loc.tabDone,
  DebateStatus.cancelled => loc.tabCancelled,
  DebateStatus.unknown => '',
};

Color _statusAccent(DebateStatus s) => switch (s) {
  DebateStatus.scheduled => JadalColors.judgesGrey,
  DebateStatus.announced => JadalColors.primaryBlue,
  DebateStatus.teamsSelected => JadalColors.deepBlue,
  DebateStatus.live => const Color(0xFF2E9E5B),
  DebateStatus.completed => JadalColors.primaryOrange,
  DebateStatus.cancelled => const Color(0xFFE53935),
  DebateStatus.unknown => JadalColors.judgesGrey,
};

/// Vibrant top hero: a blue→deepBlue gradient card with an orange radial glow in
/// the top corner + faint decorative rings, carrying the status, the debate
/// title and (once revealed) the motion. The brand's blue and orange finally
/// meet here so the top of the screen reads alive instead of flat blue.
class _HeroHeader extends StatelessWidget {
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String? motionText;
  final List<String> frameworkNames;
  final List<String> tags;
  const _HeroHeader({
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    this.motionText,
    this.frameworkNames = const [],
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dot =
        (statusColor == JadalColors.primaryBlue ||
            statusColor == JadalColors.deepBlue)
        ? Colors.white
        : statusColor;
    final hasMotion = motionText != null && motionText!.isNotEmpty;
    final hasChips = frameworkNames.isNotEmpty || tags.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // A blue→deepBlue base with the orange easing in along the diagonal so the
        // two brand colours blend smoothly instead of clashing in one corner.
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            JadalColors.deepBlue,
            JadalColors.primaryBlue,
            Color(0xFF124A8C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: JadalColors.primaryBlue.withValues(alpha: 0.30),
            blurRadius: 22,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: JadalColors.primaryOrange.withValues(alpha: 0.16),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Two soft, well-blurred orange glows of different sizes — a gentle
            // wash across the top edge rather than one hard blob in the corner.
            const Positioned(
              top: -90,
              right: -60,
              child: _Glow(size: 230, alpha: 0.30),
            ),
            const Positioned(
              top: -30,
              right: 90,
              child: _Glow(size: 120, alpha: 0.18),
            ),
            // Faint decorative rings for depth.
            const Positioned(top: 30, right: 150, child: _Ring(size: 56)),
            const Positioned(bottom: -34, left: -12, child: _Ring(size: 130)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (statusLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      height: 1.3,
                    ),
                  ),
                  if (hasMotion) ...[
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: Colors.white.withValues(alpha: 0.75),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.motion,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      motionText!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    // Frameworks + tags as small, low-key chips on the hero — they
                    // matter less than the motion, so they're translucent-white
                    // (ignoring their own brand colours, which clash on the blue).
                    if (hasChips) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final f in frameworkNames)
                            _HeroChip(label: f, filled: true),
                          for (final t in tags)
                            _HeroChip(label: t, filled: false),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft radial glow used to decorate the hero's top edge.
class _Glow extends StatelessWidget {
  final double size;
  final double alpha;
  const _Glow({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            JadalColors.primaryOrange.withValues(alpha: alpha),
            JadalColors.primaryOrange.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// A small low-key chip used for frameworks (filled) and tags (outlined) on the
/// dark hero, tinted white so it never fights the blue background.
class _HeroChip extends StatelessWidget {
  final String label;
  final bool filled;
  const _HeroChip({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: filled ? 0.16 : 0.0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: filled ? 0.0 : 0.32),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  const _Ring({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}

/// A filled, team-coloured panel: a solid colour header band (team name) over a
/// translucent body listing the speakers/members. Two of these sit side-by-side.
class _TeamColumn extends StatelessWidget {
  final String title;
  final SideInfo info;
  final Color color;

  /// Announced (sides not set) → the calm slate treatment with a touch more fill.
  final bool neutral;

  /// Live/sides-known → speaking order + reply tags; announced → plain roster.
  final bool showOrder;
  const _TeamColumn({
    required this.title,
    required this.info,
    required this.color,
    this.neutral = false,
    required this.showOrder,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dark = DebateTheme.isDark(context);
    final teamName = info.team?.name ?? title;
    final people = showOrder
        ? info.orderedSpeakers
              .map((s) => (name: s.user.name, reply: s.isReplySpeaker))
              .toList()
        : (info.members.isNotEmpty
              ? info.members.map((m) => (name: m.name, reply: false)).toList()
              : info.orderedSpeakers
                    .map((s) => (name: s.user.name, reply: false))
                    .toList());

    return Container(
      decoration: BoxDecoration(
        // A gentle team-tinted fill, kept subtle now the page background carries
        // colour of its own — no bright coloured glow competing with it. The
        // neutral (announced) slate gets a hair more fill so it reads as a solid
        // calm panel rather than washed-out grey.
        color: color.withValues(
          alpha: neutral ? (dark ? 0.18 : 0.10) : (dark ? 0.12 : 0.06),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: neutral ? 0.30 : 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.05),
            blurRadius: 12,
            spreadRadius: -6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solid team-colour header — white text stays readable on the accent.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.small(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (people.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '—',
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(color: DebateTheme.textSecondary(context)),
                    ),
                  )
                else
                  for (var i = 0; i < people.length; i++)
                    _MemberLine(
                      index: i + 1,
                      name: people[i].name,
                      color: color,
                      replyTag: people[i].reply ? loc.replyTag : null,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One member line inside a [_TeamColumn] (tuned for the narrow half-width).
class _MemberLine extends StatelessWidget {
  final int index;
  final String name;
  final Color color;
  final String? replyTag;
  const _MemberLine({
    required this.index,
    required this.name,
    required this.color,
    this.replyTag,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$index',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name.isNotEmpty ? name : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: DebateTheme.textPrimary(context)),
            ),
          ),
          if (replyTag != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                replyTag!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = DebateTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.06)
              : JadalColors.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.06),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.subtitle(context).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: DebateTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// The judges roster as a plain list of names inside the shared [_Section] card
/// (so it matches the Format block's surface + typography — no coloured circles).
/// Chair first; it's the one row that gets a distinct treatment.
class _JudgesContent extends StatelessWidget {
  final List<JudgeEntry> judges;
  const _JudgesContent({required this.judges});

  @override
  Widget build(BuildContext context) {
    // Chair first, then the rest in judge order.
    final ordered = [...judges]
      ..sort((a, b) {
        if (a.isChair != b.isChair) return a.isChair ? -1 : 1;
        return (a.judgeOrder ?? 1 << 30).compareTo(b.judgeOrder ?? 1 << 30);
      });

    return Column(
      children: [
        for (var i = 0; i < ordered.length; i++)
          _JudgeRow(judge: ordered[i], isLast: i == ordered.length - 1),
      ],
    );
  }
}

/// One judge name row. Non-chair rows are a calm neutral tile (matching the
/// section surface); the chair is orange-tinted with a star + a "Chair" pill so
/// it's the one element that stands out — no rainbow avatars.
class _JudgeRow extends StatelessWidget {
  final JudgeEntry judge;
  final bool isLast;
  const _JudgeRow({required this.judge, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dark = DebateTheme.isDark(context);
    final chair = judge.isChair;
    final name = judge.user.name.isNotEmpty ? judge.user.name : '—';

    final tileColor = chair
        ? JadalColors.primaryOrange.withValues(alpha: dark ? 0.16 : 0.10)
        : (dark
              ? Colors.white.withValues(alpha: 0.04)
              : JadalColors.primaryBlue.withValues(alpha: 0.04));

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chair
              ? JadalColors.primaryOrange.withValues(alpha: 0.45)
              : DebateTheme.textSecondary(context).withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            chair ? Icons.star_rounded : Icons.gavel_rounded,
            size: 18,
            color: chair
                ? JadalColors.primaryOrange
                : DebateTheme.textSecondary(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: chair ? FontWeight.w800 : FontWeight.w600,
                color: DebateTheme.textPrimary(context),
              ),
            ),
          ),
          if (chair)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: JadalColors.primaryOrange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                loc.chairLabel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: DebateTheme.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: AppTextStyles.button(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: JadalColors.judgesGrey,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: DebateTheme.textPrimary(context)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(loc.retry, style: AppTextStyles.button(context)),
            ),
          ],
        ),
      ),
    );
  }
}

/// While the debate is open for registration, three count buttons (Teams /
/// Judges / Solo) over `GET /registrations` (V12 §3); each opens a list dialog.
class _RegistrantsBar extends StatefulWidget {
  final int debateId;
  const _RegistrantsBar({required this.debateId});

  @override
  State<_RegistrantsBar> createState() => _RegistrantsBarState();
}

class _RegistrantsBarState extends State<_RegistrantsBar> {
  late final Future<Either<Failure, DebateRegistrations>> _future = di
      .sl<LiveDebateRepository>()
      .getRegistrations(widget.debateId);

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return _Section(
      title: loc.registrantsTitle,
      child: FutureBuilder<Either<Failure, DebateRegistrations>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return snap.data!.fold(
            (f) => Text(
              f.message,
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: DebateTheme.textSecondary(context)),
            ),
            (reg) => Row(
              children: [
                Expanded(
                  child: _CountButton(
                    icon: Icons.groups_rounded,
                    label: loc.registrantsTeamsLabel,
                    count: reg.teams.length,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _RegistrantListDialog(
                        title: loc.registeredTeamsTitle,
                        icon: Icons.groups_rounded,
                        rows: [
                          for (final t in reg.teams)
                            (
                              name: t.teamName,
                              sub: '${t.membersCount} members',
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountButton(
                    icon: Icons.gavel_rounded,
                    label: loc.registrantsJudgesLabel,
                    count: reg.judges.length,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _RegistrantListDialog(
                        title: loc.registeredJudgesTitle,
                        icon: Icons.gavel_rounded,
                        rows: [
                          for (final u in reg.judges) (name: u.name, sub: null),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountButton(
                    icon: Icons.person_rounded,
                    label: loc.registrantsSoloLabel,
                    count: reg.solo.length,
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _RegistrantListDialog(
                        title: loc.soloApplicantsTitle,
                        icon: Icons.person_rounded,
                        rows: [
                          for (final u in reg.solo) (name: u.name, sub: null),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  const _CountButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = DebateTheme.isDark(context);
    return Material(
      color: dark
          ? Colors.white.withValues(alpha: 0.05)
          : JadalColors.primaryBlue.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: JadalColors.primaryBlue, size: 22),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: AppTextStyles.subtitle(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: DebateTheme.textPrimary(context),
                ),
              ),
              Text(
                label,
                style: AppTextStyles.small(
                  context,
                ).copyWith(color: DebateTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple list dialog for a registrant group (teams/judges/solo).
class _RegistrantListDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<({String name, String? sub})> rows;
  const _RegistrantListDialog({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DebateTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
              child: Row(
                children: [
                  Icon(icon, color: JadalColors.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.subtitle(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: DebateTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: DebateTheme.textSecondary(context),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                child: Text(
                  context.loc.noneYetLabel,
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(color: DebateTheme.textSecondary(context)),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final initial = r.name.isNotEmpty
                        ? r.name.substring(0, 1).toUpperCase()
                        : '?';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: DebateTheme.surfaceElevated(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: JadalColors.primaryBlue.withValues(
                                alpha: 0.10,
                              ),
                            ),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                color: JadalColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.name.isNotEmpty ? r.name : '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DebateTheme.textPrimary(context),
                                  ),
                                ),
                                if (r.sub != null)
                                  Text(
                                    r.sub!,
                                    style: AppTextStyles.small(context)
                                        .copyWith(
                                          color: DebateTheme.textSecondary(
                                            context,
                                          ),
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
