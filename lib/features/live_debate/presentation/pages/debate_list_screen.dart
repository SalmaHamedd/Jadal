import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/appImgaeAsset.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/error/failure_text.dart';
import '../../../../core/widgets/jadal_error_view.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/models/debate_list_model.dart';
import '../../data/repositories/live_debate_repository.dart';
import '../../domain/debate_search_filter.dart';
import '../../domain/debate_status.dart';
import '../cubits/debate_list_cubit.dart';
import '../utils/debate_theme.dart';
import '../widgets/debate_filter_dialog.dart';
import '../widgets/debate_list_card.dart';
import 'backend_debate_detail_screen.dart';
import '../../../main/presentation/screens/main_screen.dart';

/// Backend debate list with stage tabs: one `GET /debates?status=…` per
/// tab (Registration / Announced / Sides selected / Live / Done / Cancelled),
/// with `meta`-driven pagination. Tapping a card opens the live-state detail.
/// A search bar + filter button replace the tabbed view with a single
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

  /// `onChanged` used to commit the query on every keystroke, and
  /// each commit fired a `/debates/search` request. The results view sequences
  /// them so there was no correctness bug, just a request storm; this coalesces
  /// a burst of typing into one call.
  Timer? _debounce;

  bool get _isFiltering => _query.isNotEmpty || !_filter.isEmpty;

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted && value != _query) setState(() => _query = value);
    });
  }

  void _toggleSearch() {
    setState(() {
      if (_searching) {
        _debounce?.cancel();
        _searchController.clear();
        _query = '';
      }
      _searching = !_searching;
    });
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<DebateSearchFilter>(
      context: context,
      builder: (_) => DebateFilterDialog(initial: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
            ),
            // The title stays put when search opens (the field now
            // lives in `bottom:`, where the stage tabs were), so the header
            // doesn't jump and the field gets full width and real padding
            // instead of being crammed into the title slot at titleSpacing 0.
            title: Text(
              loc.debatesTitle,
              // `title` (18.5), not `displayTitle` (26) — see home_screen.
              style: AppTextStyles.title(context).copyWith(color: titleColor),
            ),
            actions: [
              IconButton(
                icon: Icon(_searching ? Icons.close : Icons.search),
                onPressed: _toggleSearch,
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
            // Search replaces the stage tabs outright: `/debates/search` runs
            // across every status, so a stage selector next to it would be
            // meaningless. Gate on `_searching`, not `_isFiltering` — the tabs
            // used to linger until the first character was typed.
            bottom: _searching
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(64),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _SearchField(
                        controller: _searchController,
                        hint: loc.searchDebatesHint,
                        onChanged: _onQueryChanged,
                        onClear: _toggleSearch,
                      ),
                    ),
                  )
                : _isFiltering
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
          // Opening search switches straight to the cross-status result list
          // (an empty query returns everything), so the stage tabs never sit
          // underneath a search field.
          body: (_searching || _isFiltering)
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

/// The debates search field: a proper contained input with padding,
/// sitting full-width where the stage tabs normally are.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final dark = DebateTheme.isDark(context);
    return TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      style: AppTextStyles.body(context).copyWith(
        color: DebateTheme.textPrimary(context),
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body(
          context,
        ).copyWith(color: DebateTheme.textSecondary(context)),
        filled: true,
        fillColor: DebateTheme.surfaceElevated(context),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: DebateTheme.textSecondary(context),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: 18,
            color: DebateTheme.textSecondary(context),
          ),
          onPressed: onClear,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.10)
                : JadalColors.primaryBlue.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.10)
                : JadalColors.primaryBlue.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: JadalColors.primaryOrange,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

/// The combined search+filter result list — a flat paginated list
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

  /// Sequences requests: a query/filter change invalidates any
  /// in-flight response (which used to land in the freshly-cleared list) and
  /// releases the `_loading` latch that used to swallow the reload.
  int _requestSeq = 0;

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
      _requestSeq++; // drop whatever is still in flight
      _items.clear();
      _page = 1;
      _hasMore = true;
      _loading = false;
      _load();
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300)
      _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await di.sl<LiveDebateRepository>().searchDebates(
      widget.filter.copyWith(q: widget.query.isEmpty ? null : widget.query),
      page: _page,
    );
    if (!mounted || seq != _requestSeq) return;
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (pageData) => setState(() {
        _items.addAll(pageData.items);
        // Meta-driven: the old items.isNotEmpty heuristic left
        // _hasMore stuck on true after the last page, so the footer spinner
        // kept showing after the results had already been returned.
        _hasMore = pageData.meta.hasMore;
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
        return DebateListCard(
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
                    return DebateListCard(
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

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // The raw failure string used to be printed here verbatim, which is how a
    // transport exception ended up on screen. Everything goes through
    // FailureText now, and the retry control is the shared one.
    return JadalErrorView(
      message: FailureText.fromMessage(context, message),
      onRetry: onRetry,
    );
  }
}
