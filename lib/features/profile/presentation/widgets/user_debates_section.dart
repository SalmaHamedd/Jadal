import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/features/live_debate/presentation/pages/backend_debate_detail_screen.dart';

const int kLatestDebatesPreviewCount = 5;

/// Latest debates (done/cancelled) for a user (§6.2 debater/judge sections) —
/// a compact preview here, with a "Show all" opening the same query in a
/// simple paginated list, scoped via `GET /debates/search?user_id[]=`.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.loc.latestDebates,
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(fontWeight: FontWeight.w800, color: textColor),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      UserDebatesListScreen(userId: userId, userName: userName),
                ),
              ),
              child: Text(
                context.loc.showAll,
                style: AppTextStyles.button(context),
              ),
            ),
          ],
        ),
        for (final d in latest) _DebateTile(item: d),
      ],
    );
  }
}

class _DebateTile extends StatelessWidget {
  final DebateListItem item;
  const _DebateTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        item.status.wire == 'cancelled'
            ? Icons.cancel_outlined
            : Icons.emoji_events_outlined,
        color: item.status.wire == 'cancelled'
            ? JadalColors.negativeRed
            : JadalColors.primaryOrange,
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body(context).copyWith(
          color: isDark
              ? JadalColors.darkTextPrimary
              : JadalColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        item.status.wire == 'cancelled'
            ? context.loc.tabCancelled
            : context.loc.tabDone,
        style: AppTextStyles.small(
          context,
        ).copyWith(color: JadalColors.judgesGrey),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BackendDebateDetailScreen(debateId: item.id, title: item.title),
        ),
      ),
    );
  }
}

/// Full paginated "show all" list for [UserDebatesSection], scoped to one
/// user via the same debate-search endpoint (§8).
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
        ),
        body: _items.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(
                child: Text(
                  context.loc.noDebatesYet,
                  style: AppTextStyles.body(context),
                ),
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 200)
                    _loadMore();
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _DebateTile(item: _items[i]),
                ),
              ),
      ),
    );
  }
}
