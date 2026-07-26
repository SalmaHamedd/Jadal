import 'package:flutter/material.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/achievement.dart';
import 'package:jadal_app/features/profile/presentation/widgets/achievement_badge.dart';

/// Full paginated achievements list (§6.3 "Show all") for a given user.
class AchievementsScreen extends StatefulWidget {
  final int userId;
  final String userName;
  const AchievementsScreen({super.key, required this.userId, required this.userName});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final ProfileRepository _repo = ProfileRepository();
  final List<Achievement> _items = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final res = await _repo.getUserAchievements(widget.userId, page: _page);
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
          title: Text('${widget.userName} — Achievements',
              style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _items.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty && _error != null
                ? Center(child: Text(_error!, style: const TextStyle(fontFamily: 'Cairo')))
                : _items.isEmpty
                    ? const Center(child: Text('No achievements yet', style: TextStyle(fontFamily: 'Cairo')))
                    : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) _loadMore();
                          return false;
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= _items.length) {
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            return Center(
                              child: AchievementBadge(achievement: _items[i], size: 72),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
