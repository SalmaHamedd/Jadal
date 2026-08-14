import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/features/live_debate/presentation/pages/backend_debate_detail_screen.dart';
import 'package:jadal_app/features/live_debate/presentation/widgets/debate_list_card.dart';

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
            if (i != 0) const SizedBox(height: 10),
            DebateListCard(
              item: latest[i],
              showStatusPill: true,
              // Sits inside the section's own card, so it has far less width
              // than the debates screen.
              compact: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BackendDebateDetailScreen(
                    debateId: latest[i].id,
                    title: latest[i].title,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full paginated "show all" list, scoped to one user via the same
/// debate-search endpoint (§8). Uses the same [DebateListCard] as the preview
/// so opening "show all" feels like the section expanding, not a different
/// screen.
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
                        return DebateListCard(
                          item: _items[i],
                          showStatusPill: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BackendDebateDetailScreen(
                                debateId: _items[i].id,
                                title: _items[i].title,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
