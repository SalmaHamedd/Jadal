import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/features/debates/presentation/screens/judge_session_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/debate.dart';
import '../../domain/repositories/debate_repositories.dart';
import '../cubits/debates_list_cubit.dart';
import '../widgets/debate_card.dart';
import 'debate_detail_screen.dart';
import 'live_session_debater_screen.dart';
import 'post_session_results_screen.dart';
import 'preparation_room_screen.dart';

enum DebatesListMode { debater, judge }

class DebatesListScreen extends StatelessWidget {
  final DebatesListMode mode;

  const DebatesListScreen({super.key, this.mode = DebatesListMode.debater});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DebatesListCubit>(
      create: (_) => DebatesListCubit(di.sl<DebatesRepository>())..load(),
      child: _DebatesListView(mode: mode),
    );
  }
}

class _DebatesListView extends StatelessWidget {
  final DebatesListMode mode;
  const _DebatesListView({required this.mode});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(mode == DebatesListMode.judge
              ? 'مناظرات للحكم'
              : 'المناظرات'),
          bottom: const TabBar(
            indicatorColor: JadalColors.primaryOrange,
            indicatorWeight: 3,
            labelColor: JadalColors.primaryOrange,
            unselectedLabelColor: JadalColors.judgesGrey,
            tabs: [
              Tab(text: 'قادمة'),
              Tab(text: 'مباشرة'),
              Tab(text: 'منتهية'),
            ],
          ),
        ),
        body: BlocBuilder<DebatesListCubit, DebatesListState>(
          builder: (context, state) {
            if (state.status == DebatesListStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == DebatesListStatus.error) {
              return Center(child: Text(state.error ?? 'حدث خطأ'));
            }
            return Column(
              children: [
                if (mode == DebatesListMode.judge) const _JudgeFilterBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DebatesTab(items: state.upcoming, mode: mode),
                      _DebatesTab(items: state.live, mode: mode),
                      _DebatesTab(items: state.past, mode: mode),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JudgeFilterBar extends StatelessWidget {
  const _JudgeFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebatesListCubit, DebatesListState>(
      buildWhen: (a, b) => a.judgeFilter != b.judgeFilter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              for (final f in JudgeFilter.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(_label(f)),
                    selected: state.judgeFilter == f,
                    onSelected: (_) =>
                        context.read<DebatesListCubit>().setJudgeFilter(f),
                    selectedColor: JadalColors.primaryOrange.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontFamily: 'Cairo',
                      color: state.judgeFilter == f
                          ? JadalColors.primaryOrange
                          : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _label(JudgeFilter f) => switch (f) {
        JudgeFilter.all => 'الكل',
        JudgeFilter.openForJudges => 'مفتوح للحكام',
        JudgeFilter.assignedToMe => 'المعيّن لي',
      };
}

class _DebatesTab extends StatelessWidget {
  final List<Debate> items;
  final DebatesListMode mode;
  const _DebatesTab({required this.items, required this.mode});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: JadalColors.primaryOrange,
      onRefresh: () => context.read<DebatesListCubit>().load(),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(48),
              children: const [
                Center(child: Text('لا توجد مناظرات في هذه الفئة.')),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, i) => DebateCard(
                debate: items[i],
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => JudgeSessionScreen(debate: items[i]),
                  ),
                ),
                trailingCta: _CtaButton(debate: items[i], mode: mode),
              ),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
    );
  }

  void _openDetail(BuildContext context, Debate debate) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DebateDetailScreen(debate: debate)),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final Debate debate;
  final DebatesListMode mode;
  const _CtaButton({required this.debate, required this.mode});

  @override
  Widget build(BuildContext context) {
    if (mode == DebatesListMode.judge) {
      return _OrangePill(
        label: 'سجّل كحكم',
        onPressed: () => _snack(context, 'تم التسجيل كحكم.'),
      );
    }

    switch (debate.status) {
      case DebateLifecycle.upcoming:
        return _OrangePill(
          label: 'سجّل',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PreparationRoomScreen(debate: debate),
            ),
          ),
        );
      case DebateLifecycle.live:
        return _OrangePill(
          label: 'انضم الآن',
          icon: Icons.podcasts,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LiveSessionDebaterScreen(debate: debate),
            ),
          ),
        );
      case DebateLifecycle.past:
        return _OrangePill(
          label: 'النتائج',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostSessionResultsScreen(debate: debate),
            ),
          ),
        );
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _OrangePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _OrangePill({required this.label, this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JadalColors.primaryOrange,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
