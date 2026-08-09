import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/features/live_debate/presentation/pages/backend_debate_detail_screen.dart';

const int kLatestDebatesPreviewCount = 5;

/// Latest debates (done/cancelled) for a user.
///
/// These were bare [ListTile]s painted straight onto the page — no container,
/// no separation, an icon and two grey lines. Each debate is now a proper
/// tinted row: a status-coloured icon plate, the title, and a status pill, so
/// a completed debate is distinguishable from a cancelled one at a glance.
class UserDebatesSection extends StatelessWidget {
  final int userId;
  final String userName;
  final List<DebateListItem> latest;
  const UserDebatesSection({
    super.key,
    required this.userId,
    required this.userName,
    required this.latest,
  });

  @override
  Widget build(BuildContext context) {
    if (latest.isEmpty) return const SizedBox.shrink();
    return JadalSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JadalSectionHeader(
            icon: Icons.forum_rounded,
            title: context.loc.latestDebates,
            actionLabel: context.loc.showAll,
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    UserDebatesListScreen(userId: userId, userName: userName),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < latest.length; i++) ...[
            if (i != 0) const SizedBox(height: 8),
            DebateRowCard(item: latest[i]),
          ],
        ],
      ),
    );
  }
}

/// One debate as a self-contained tinted row. Shared by the profile preview
/// and the full "show all" list so the two never drift apart.
class DebateRowCard extends StatelessWidget {
  final DebateListItem item;
  const DebateRowCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cancelled = item.status.wire == 'cancelled';
    final accent = cancelled ? JadalColors.negativeRed : JadalColors.primaryOrange;
    final dark = jadalIsDark(context);
    final radius = BorderRadius.circular(16);

    return Material(
      color: accent.withValues(alpha: dark ? 0.10 : 0.06),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BackendDebateDetailScreen(debateId: item.id, title: item.title),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: accent.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: dark ? 0.24 : 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  cancelled
                      ? Icons.cancel_rounded
                      : Icons.emoji_events_rounded,
                  size: 20,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: jadalTextPrimary(context),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: dark ? 0.26 : 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cancelled
                            ? context.loc.tabCancelled
                            : context.loc.tabDone,
                        style: AppTextStyles.small(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
                color: jadalTextSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full paginated "show all" list, scoped to one user via the same
/// debate-search endpoint (§8). Uses the same [DebateRowCard] as the preview
/// so opening "show all" feels like the section expanding, not a different
/// screen — it used to be an undecorated `ListView` of divider-separated
/// tiles, which is why it read as worse than the preview it came from.
class UserDebatesListScreen extends StatefulWidget {
  final int userId;
  final String userName;
  const UserDebatesListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDebatesListScreen> createState() => _UserDebatesListScreenState();
}

class _UserDebatesListScreenState extends State<UserDebatesListScreen> {
  final List<DebateListItem> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final repo = di.sl<LiveDebateRepository>();
    final res = await repo.searchDebates(
      DebateSearchFilter(
        userIds: [widget.userId],
        status: const ['completed', 'cancelled'],
      ),
      page: _page,
    );
    if (!mounted) return;
    res.fold(
      (f) => setState(() => _loading = false),
      (page) => setState(() {
        _items.addAll(page.items);
        _hasMore = page.items.isNotEmpty;
        _page++;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return JadalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            context.loc.userDebatesTitle(widget.userName),
            style: AppTextStyles.title(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: _items.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(
                    child: Text(
                      context.loc.noDebatesYet,
                      style: AppTextStyles.body(context)
                          .copyWith(color: jadalTextSecondary(context)),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      // One trailing slot for the pager's spinner.
                      itemCount: _items.length + (_loading ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        if (i >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          );
                        }
                        return DebateRowCard(item: _items[i]);
                      },
                    ),
                  ),
      ),
    );
  }
}
