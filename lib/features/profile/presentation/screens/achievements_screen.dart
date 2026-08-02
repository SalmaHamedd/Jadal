import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievement_badge.dart';

/// §6.8 — how the "show all" page orders its list. Wire values match the
/// backend's `sort` parameter (BACKEND_RESPONSE §4).
enum AchievementSort {
  date('date'),
  rank('rank');

  final String wire;
  const AchievementSort(this.wire);
}

/// Full paginated achievements list ("Show all", §6.8) for a given user, with
/// a segmented Date | Tier control up top (default: Date) and a loading
/// indicator centered in the screen rather than inline in the grid.
class AchievementsScreen extends StatefulWidget {
  final int userId;
  final String userName;
  const AchievementsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final ProfileRepository _repo = ProfileRepository();
  final List<Achievement> _items = [];
  AchievementSort _sort = AchievementSort.date;
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  void _setSort(AchievementSort sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _requestSeq++; // drop any in-flight page of the old ordering
      _items.clear();
      _page = 1;
      _hasMore = true;
      _loading = false;
      _error = null;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final seq = ++_requestSeq;
    setState(() => _loading = true);
    final res = await _repo.getUserAchievements(
      widget.userId,
      page: _page,
      sort: _sort.wire,
    );
    if (!mounted || seq != _requestSeq) return;
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (items) => setState(() {
        _items.addAll(items);
        _hasMore = items.isNotEmpty;
        _page++;
        _loading = false;
        _error = null;
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
            context.loc.userAchievementsTitle(widget.userName),
            style: AppTextStyles.title(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _SortSwitch(active: _sort, onChanged: _setSort),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return Center(
        child: Text(_error!, style: AppTextStyles.body(context)),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          context.loc.noAchievementsYet,
          style: AppTextStyles.body(context),
        ),
      );
    }
    // §6.8 — while a next page loads, the indicator is centered over the
    // screen instead of rendered inline next to the last achievement.
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
              _loadMore();
            }
            return false;
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemCount: _items.length,
            itemBuilder: (context, i) => Center(
              child: AchievementBadge(achievement: _items[i], size: 80),
            ),
          ),
        ),
        if (_loading)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

/// The Date | Tier segmented control (§6.8) — same pill-toggle look as the
/// public statistics scope switch.
class _SortSwitch extends StatelessWidget {
  final AchievementSort active;
  final ValueChanged<AchievementSort> onChanged;
  const _SortSwitch({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final sort in AchievementSort.values)
            Expanded(
              child: _SortButton(
                label: sort == AchievementSort.date
                    ? context.loc.achievementsSortDate
                    : context.loc.achievementsSortRank,
                icon: sort == AchievementSort.date
                    ? Icons.calendar_month_rounded
                    : Icons.military_tech_rounded,
                selected: sort == active,
                onTap: () => onChanged(sort),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SortButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor =
        dark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary;
    final mutedColor =
        (dark ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary)
            .withValues(alpha: 0.6);
    return Material(
      color: selected
          ? JadalColors.primaryOrange.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? selectedColor : mutedColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? selectedColor : mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
