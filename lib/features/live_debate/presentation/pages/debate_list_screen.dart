import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_gradient_background.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/models/debate_list_model.dart';
import '../../data/repositories/live_debate_repository.dart';
import '../../domain/debate_status.dart';
import '../cubits/debate_list_cubit.dart';
import '../utils/debate_date.dart';
import '../utils/debate_theme.dart';
import 'backend_debate_detail_screen.dart';

/// Backend debate list with stage tabs (§13): one `GET /debates?status=…` per
/// tab (Registration / Announced / Sides selected / Live / Done / Cancelled),
/// with `meta`-driven pagination. Tapping a card opens the live-state detail.
class DebateListScreen extends StatelessWidget {
  const DebateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final tabs = <({String label, String status})>[
      (label: loc.tabRegistration, status: DebateStatus.scheduled.wire),
      (label: loc.tabAnnounced, status: DebateStatus.announced.wire),
      (label: loc.tabSidesSelected, status: DebateStatus.teamsSelected.wire),
      (label: loc.tabLive, status: DebateStatus.live.wire),
      (label: loc.tabDone, status: DebateStatus.completed.wire),
      (label: loc.tabCancelled, status: DebateStatus.cancelled.wire),
    ];

    // Light mode is blue-led (orange barely shows otherwise); dark keeps orange.
    final tabColor =
        DebateTheme.isDark(context) ? JadalColors.primaryOrange : JadalColors.primaryBlue;

    return DefaultTabController(
      length: tabs.length,
      child: JadalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(loc.debatesTitle,
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
            // The statistics entry moved to the Profile tab.
            bottom: TabBar(
              isScrollable: true,
              // Removes the empty gap the scrollable TabBar leaves at the start/end.
              tabAlignment: TabAlignment.start,
              indicatorColor: tabColor,
              indicatorWeight: 3,
              labelColor: tabColor,
              unselectedLabelColor: JadalColors.judgesGrey,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
              tabs: [for (final t in tabs) Tab(text: t.label)],
            ),
          ),
          body: TabBarView(
            children: [for (final t in tabs) _StatusTab(status: t.status)],
          ),
        ),
      ),
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String status;
  const _StatusTab({required this.status});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DebateListCubit(repo: di.sl<LiveDebateRepository>(), statusFilter: status)..load(),
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
        final showFooter = state.hasMore || state.status == DebateListStatus.loadingMore;
        return RefreshIndicator(
          color: JadalColors.primaryOrange,
          onRefresh: cubit.refresh,
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Center(
                      child: Text(loc.noDebatesHere,
                          style: TextStyle(
                              fontFamily: 'Cairo', color: DebateTheme.textSecondary(context))),
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
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            BackendDebateDetailScreen(debateId: item.id, title: item.title),
                      )),
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
                        colors: [JadalColors.primaryBlue, JadalColors.primaryOrange],
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
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
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
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
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
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: JadalColors.primaryOrange
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(item.tag!,
                                      style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: JadalColors.primaryOrange)),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (item.format.name != null) ...[
                                Icon(Icons.tune_rounded,
                                    size: 15,
                                    color: DebateTheme.textSecondary(context)),
                                const SizedBox(width: 5),
                                Text(item.format.name!,
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.5,
                                        color: DebateTheme.textSecondary(context))),
                                const SizedBox(width: 14),
                              ],
                              if (item.scheduledAt != null) ...[
                                Icon(Icons.event_rounded,
                                    size: 15,
                                    color: DebateTheme.textSecondary(context)),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    formatDebateDate(item.scheduledAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.5,
                                        color: DebateTheme.textSecondary(context)),
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
            const Icon(Icons.cloud_off_rounded, size: 56, color: JadalColors.judgesGrey),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', color: DebateTheme.textPrimary(context))),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(loc.retry, style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }
}

