import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jadal_app/core/function/media_url.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/avatar_palette.dart';
import 'package:jadal_app/core/error/failure_text.dart';
import 'package:jadal_app/core/widgets/jadal_error_view.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/home/data/home_prefetch.dart';
import 'package:jadal_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:jadal_app/features/statistics/data/models/leaderboard_models.dart';
import 'package:jadal_app/features/statistics/data/repositories/leaderboard_repository.dart';
import 'package:jadal_app/features/statistics/presentation/pages/public_stats_screen.dart';

/// Home's "top debaters" block, rendered as a **podium** rather than three
/// list rows.
///
/// A ranked list of three is visually indistinguishable from every other list
/// in the app, which is exactly why this section used to feel like filler. A
/// podium reads as a result at a glance: the winner is centred and raised,
/// second and third flank them, and each plinth is sized by rank.
class TopDebatersPreview extends StatefulWidget {
  /// Bumped by Home on pull-to-refresh. This section owns its own fetch (it is
  /// not driven by a cubit Home can reload), so it needs an explicit nudge —
  /// otherwise a refresh reloads everything except this block.
  final int refreshTick;

  const TopDebatersPreview({super.key, this.refreshTick = 0});

  @override
  State<TopDebatersPreview> createState() => _TopDebatersPreviewState();
}

class _TopDebatersPreviewState extends State<TopDebatersPreview> {
  bool _loading = true;
  List<LeaderboardEntry> _top = const [];

  /// Set when the fetch failed.
  ///
  /// This used to be swallowed (`res.fold((_) {}, …)`), which combined with the
  /// "hide when empty" guard below meant that opening the app with no network
  /// made this whole section **disappear** — while every other block showed an
  /// error and recovered once the connection came back. It never returned,
  /// because nothing re-ran the fetch. Now a failure is a visible, retryable
  /// state like everywhere else.
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TopDebatersPreview old) {
    super.didUpdateWidget(old);
    // Home pulls-to-refresh by rebuilding with a new refresh tick; without
    // this the section would keep whatever it fetched on first mount.
    if (old.refreshTick != widget.refreshTick) _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    // §4.1 — consume the splash-time prefetch when present.
    final res =
        await (HomePrefetch.takeLeaderboard() ??
            di.sl<LeaderboardRepository>().getLeaderboard(
              LeaderboardScope.debaters,
              LeaderboardMetric.points,
            ));
    if (!mounted) return;
    setState(() {
      _loading = false;
      res.fold((f) => _error = f.message, (board) {
        _error = null;
        _top = board.entries.take(3).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hide only when the load SUCCEEDED and there is genuinely nothing to
    // show. A failure must never look like "no data".
    if (!_loading && _error == null && _top.isEmpty) {
      return const SizedBox.shrink();
    }
    // Podium order: 2nd on the leading side, 1st centred, 3rd trailing.
    LeaderboardEntry? at(int rank) {
      for (final e in _top) {
        if (e.rank == rank) return e;
      }
      return null;
    }

    return JadalSurface(
      accent: JadalColors.primaryBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JadalSectionHeader(
            icon: Icons.leaderboard_rounded,
            title: context.loc.topDebaters,
            actionLabel: context.loc.showMore,
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublicStatsScreen()),
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const SizedBox(
              height: 168,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (_error != null)
            JadalErrorView(
              compact: true,
              message: FailureText.fromMessage(context, _error),
              onRetry: _load,
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _Plinth(entry: at(2), rank: 2)),
                const SizedBox(width: 10),
                Expanded(child: _Plinth(entry: at(1), rank: 1)),
                const SizedBox(width: 10),
                Expanded(child: _Plinth(entry: at(3), rank: 3)),
              ],
            ),
        ],
      ),
    );
  }
}

/// One podium position. Height, avatar size and the medal treatment all scale
/// with [rank], so the hierarchy is readable without reading any numbers.
class _Plinth extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int rank;
  const _Plinth({required this.entry, required this.rank});

  static const _colors = <int, Color>{
    1: Color(0xFFD4A017),
    2: Color(0xFF9AA0A6),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final color = _colors[rank]!;
    final first = rank == 1;
    final avatarRadius = first ? 30.0 : 24.0;
    final plinthHeight = switch (rank) {
      1 => 62.0,
      2 => 46.0,
      _ => 36.0,
    };
    final dark = jadalIsDark(context);

    // An empty slot still occupies its column so the podium keeps its shape
    // when the leaderboard has fewer than three entries.
    if (e == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: avatarRadius * 2 + 34),
          _base(context, color, plinthHeight, dark, muted: true),
        ],
      );
    }

    final url = resolveMediaUrl(e.imageUrl);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UserProfileScreen(userId: e.subjectId, userName: e.name),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown only on the winner — a small, earned flourish.
          if (first)
            Icon(Icons.workspace_premium_rounded, size: 20, color: color)
          else
            const SizedBox(height: 20),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: first ? 2.5 : 2),
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: userAvatarColor(e.subjectId),
              backgroundImage: url != null
                  ? CachedNetworkImageProvider(url)
                  : null,
              child: url == null
                  ? Text(
                      e.name.isEmpty
                          ? '?'
                          : e.name.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.subtitle(context).copyWith(
                        fontWeight: FontWeight.w900,
                        color: userAvatarForeground(
                          userAvatarColor(e.subjectId),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            e.name,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small(context).copyWith(
              fontWeight: FontWeight.w800,
              color: jadalTextPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          _base(
            context,
            color,
            plinthHeight,
            dark,
            value: LeaderboardRow.formatValue(
              LeaderboardMetric.points,
              e.value,
            ),
          ),
        ],
      ),
    );
  }

  /// The plinth itself: a tinted block whose height encodes the rank, with the
  /// rank numeral and the points value stacked inside it.
  Widget _base(
    BuildContext context,
    Color color,
    double height,
    bool dark, {
    String? value,
    bool muted = false,
  }) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: muted ? 0.05 : (dark ? 0.22 : 0.13)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
          bottom: Radius.circular(6),
        ),
        border: Border.all(color: color.withValues(alpha: muted ? 0.10 : 0.35)),
      ),
      child: muted
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rank',
                  style: AppTextStyles.subtitle(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: jadalTextSecondary(context),
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
