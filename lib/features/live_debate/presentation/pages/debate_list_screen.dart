import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/appImgaeAsset.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/models/debate_list_model.dart';
import '../../data/repositories/live_debate_repository.dart';
import '../../domain/debate_search_filter.dart';
import '../../domain/debate_status.dart';
import '../cubits/debate_list_cubit.dart';
import '../utils/debate_date.dart';
import '../utils/debate_theme.dart';
import '../widgets/debate_filter_dialog.dart';
import 'backend_debate_detail_screen.dart';
import '../../../main/presentation/screens/main_screen.dart';

/// Backend debate list with stage tabs (§13): one `GET /debates?status=…` per
/// tab (Registration / Announced / Sides selected / Live / Done / Cancelled),
/// with `meta`-driven pagination. Tapping a card opens the live-state detail.
/// A search bar + filter button (§8) replace the tabbed view with a single
/// searched/filtered result list whenever a query or filter is active.
class DebateListScreen extends StatefulWidget {
  const DebateListScreen({super.key});

  @override
  State<DebateListScreen> createState() => _DebateListScreenState();
}

class _DebateListScreenState extends State<DebateListScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();
  String _query = '';
  DebateSearchFilter _filter = const DebateSearchFilter();

  bool get _isFiltering => _query.isNotEmpty || !_filter.isEmpty;

  Future<void> _openFilterDialog() async {
    final result = await showDialog<DebateSearchFilter>(
      context: context,
      builder: (_) => DebateFilterDialog(initial: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.deepBlue;
    final tabs = <({String label, String status})>[
      (label: loc.tabRegistration, status: DebateStatus.scheduled.wire),
      (label: loc.tabAnnounced, status: DebateStatus.announced.wire),
      (label: loc.tabSidesSelected, status: DebateStatus.teamsSelected.wire),
      (label: loc.tabLive, status: DebateStatus.live.wire),
      (label: loc.tabDone, status: DebateStatus.completed.wire),
      (label: loc.tabCancelled, status: DebateStatus.cancelled.wire),
    ];

    // Light mode is blue-led (orange barely shows otherwise); dark keeps orange.
    final tabColor = DebateTheme.isDark(context)
        ? JadalColors.primaryOrange
        : JadalColors.primaryBlue;

    return DefaultTabController(
      length: tabs.length,
      child: JadalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 0,
            leading: _searching
                ? null
                : IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
                  ),
            title: _searching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    decoration: InputDecoration(
                      hintText: loc.debatesTitle,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  )
                : Text(
                    loc.debatesTitle,
                    style: AppTextStyles.displayTitle(
                      context,
                    ).copyWith(color: titleColor),
                  ),
            actions: [
              IconButton(
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  if (_searching) {
                    _searchController.clear();
                    _query = '';
                  }
                  _searching = !_searching;
                }),
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: !_filter.isEmpty,
                  smallSize: 8,
                  child: const Icon(Icons.filter_list_rounded),
                ),
                onPressed: _openFilterDialog,
              ),
            ],
            // The statistics entry moved to the Profile tab.
            bottom: _isFiltering
                ? null
                : TabBar(
                    isScrollable: true,
                    // Removes the empty gap the scrollable TabBar leaves at the start/end.
                    tabAlignment: TabAlignment.start,
                    indicatorColor: tabColor,
                    indicatorWeight: 3,
                    labelColor: tabColor,
                    unselectedLabelColor: JadalColors.judgesGrey,
                    labelStyle: AppTextStyles.button(context),
                    tabs: [for (final t in tabs) Tab(text: t.label)],
                  ),
          ),
          body: _isFiltering
              ? _SearchResultsView(query: _query, filter: _filter)
              : TabBarView(
                  children: [
                    for (final t in tabs) _StatusTab(status: t.status),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The combined search+filter result list (§8) — a flat paginated list
/// (no status tabs) driven by `GET /debates/search`.
class _SearchResultsView extends StatefulWidget {
  final String query;
  final DebateSearchFilter filter;
  const _SearchResultsView({required this.query, required this.filter});

  @override
  State<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<_SearchResultsView> {
  final _scroll = ScrollController();
  final List<DebateListItem> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void didUpdateWidget(covariant _SearchResultsView old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query || old.filter != widget.filter) {
      _items.clear();
      _page = 1;
      _hasMore = true;
      _load();
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300)
      _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await di.sl<LiveDebateRepository>().searchDebates(
      widget.filter.copyWith(q: widget.query.isEmpty ? null : widget.query),
      page: _page,
    );
    if (!mounted) return;
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (pageData) => setState(() {
        _items.addAll(pageData.items);
        _hasMore = pageData.items.isNotEmpty;
        _page++;
        _loading = false;
      }),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return _ErrorRetry(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DebateTheme.textSecondary(
                  context,
                ).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                AppImageAsset.emptyDebatesIllustration,
                height: 160,
                errorBuilder: (_, _, _) => const SizedBox(height: 160),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              loc.noDebatesHere,
              style: AppTextStyles.body(
                context,
              ).copyWith(color: DebateTheme.textSecondary(context)),
            ),
          ),
        ],
      );
    }
    final showFooter = _hasMore || _loading;
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = _items[i];
        return _DebateListCard(
          item: item,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BackendDebateDetailScreen(
                debateId: item.id,
                title: item.title,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String status;
  const _StatusTab({required this.status});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebateListCubit(
        repo: di.sl<LiveDebateRepository>(),
        statusFilter: status,
      )..load(),
      child: const _StatusList(),
    );
  }
}

class _StatusList extends StatefulWidget {
  const _StatusList();

  @override
  State<_StatusList> createState() => _StatusListState();
}

class _StatusListState extends State<_StatusList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<DebateListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final cubit = context.read<DebateListCubit>();
    return BlocBuilder<DebateListCubit, DebateListState>(
      builder: (context, state) {
        if (state.status == DebateListStatus.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DebateListStatus.error && state.items.isEmpty) {
          return _ErrorRetry(message: state.error ?? '', onRetry: cubit.load);
        }
        final showFooter =
            state.hasMore || state.status == DebateListStatus.loadingMore;
        return RefreshIndicator(
          color: JadalColors.primaryOrange,
          onRefresh: cubit.refresh,
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DebateTheme.textSecondary(
                            context,
                          ).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          AppImageAsset.emptyDebatesIllustration,
                          height: 160,
                          errorBuilder: (_, _, _) =>
                              const SizedBox(height: 160),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        loc.noDebatesHere,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: DebateTheme.textSecondary(context)),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (showFooter ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = state.items[i];
                    return _DebateListCard(
                      item: item,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BackendDebateDetailScreen(
                            debateId: item.id,
                            title: item.title,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _DebateListCard extends StatelessWidget {
  final DebateListItem item;
  final VoidCallback onTap;
  const _DebateListCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = DebateTheme.isDark(context);
    final radius = BorderRadius.circular(20);
    // Every card floats the SAME way — one soft neutral elevation, no per-stage
    // colour. The single blue→orange accent stripe is the only brand colour and
    // it's identical on every card, so the list reads calm and elegant.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.36 : 0.08),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            // A hairline keeps the elevated surface from melting into the dark
            // blue background.
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : JadalColors.primaryBlue.withValues(alpha: 0.06),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          JadalColors.primaryBlue,
                          JadalColors.primaryOrange,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title(context).copyWith(
                              height: 1.3,
                              color: DebateTheme.textPrimary(context),
                            ),
                          ),
                          // Registration cards show only title/format/date (§U2).
                          if (item.status != DebateStatus.scheduled &&
                              item.motion?.text.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.motion!.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(context).copyWith(
                                height: 1.4,
                                color: DebateTheme.textSecondary(context),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (item.tag != null && item.tag!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: JadalColors.primaryOrange.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.tag!,
                                    style: AppTextStyles.small(context)
                                        .copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: JadalColors.primaryOrange,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (item.format.name != null) ...[
                                Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: DebateTheme.textSecondary(context),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  item.format.name!,
                                  style: AppTextStyles.caption(context)
                                      .copyWith(
                                        color: DebateTheme.textSecondary(
                                          context,
                                        ),
                                      ),
                                ),
                                const SizedBox(width: 14),
                              ],
                              if (item.scheduledAt != null) ...[
                                Icon(
                                  Icons.event_rounded,
                                  size: 15,
                                  color: DebateTheme.textSecondary(context),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    formatDebateDate(item.scheduledAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(context)
                                        .copyWith(
                                          color: DebateTheme.textSecondary(
                                            context,
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

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
              Icons.cloud_off_rounded,
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
