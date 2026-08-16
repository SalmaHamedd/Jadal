import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/home/data/home_prefetch.dart';
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/presentation/pages/backend_debate_detail_screen.dart';

enum _BannerKind { live, registration, done }

class _BannerEntry {
  final _BannerKind kind;
  final DebateListItem debate;
  const _BannerEntry(this.kind, this.debate);
}

/// The home screen's rotating debate banner — the one deliberately colorful
/// element on an otherwise calm home screen. Cycles through up to three
/// states (live now / open for registration / latest result) every 6s, or on
/// a manual swipe; shows whichever subset actually has a debate, and a
/// friendly fallback if none of the three do.
class HomeDebateBanner extends StatefulWidget {
  const HomeDebateBanner({super.key});

  @override
  State<HomeDebateBanner> createState() => _HomeDebateBannerState();
}

class _HomeDebateBannerState extends State<HomeDebateBanner> {
  final _pageController = PageController();
  Timer? _timer;
  bool _loading = true;
  List<_BannerEntry> _entries = const [];
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Consume the splash-time prefetch when present; otherwise fetch
    // as before.
    final repo = di.sl<LiveDebateRepository>();
    final liveRes = await (HomePrefetch.takeLive() ??
        repo.getDebates(status: 'live', perPage: 1));
    final regRes = await (HomePrefetch.takeScheduled() ??
        repo.getDebates(status: 'scheduled', perPage: 1));
    final doneRes = await (HomePrefetch.takeCompleted() ??
        repo.getDebates(status: 'completed', perPage: 1));
    if (!mounted) return;
    final entries = <_BannerEntry>[];
    liveRes.fold((_) {}, (p) {
      if (p.items.isNotEmpty)
        entries.add(_BannerEntry(_BannerKind.live, p.items.first));
    });
    regRes.fold((_) {}, (p) {
      if (p.items.isNotEmpty)
        entries.add(_BannerEntry(_BannerKind.registration, p.items.first));
    });
    doneRes.fold((_) {}, (p) {
      if (p.items.isNotEmpty)
        entries.add(_BannerEntry(_BannerKind.done, p.items.first));
    });
    setState(() {
      _entries = entries;
      _loading = false;
    });
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_entries.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_page + 1) % _entries.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_entries.isEmpty) {
      return _BannerCard(
        gradient: const [JadalColors.primaryBlue, JadalColors.deepBlue],
        icon: Icons.forum_rounded,
        badge: null,
        title: 'No debates right now',
        subtitle: 'Check back soon — new debates are added regularly',
        onTap: null,
      );
    }
    return SizedBox(
      height: 140,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _entries.length,
              onPageChanged: (i) {
                // setState so the dot indicator below tracks the page in the
                // same frame — a bare field write only repaints whenever some
                // unrelated rebuild happens to fire, visibly lagging on swipe.
                setState(() => _page = i);
                _restartTimer(); // a manual swipe resets the 6s cadence
              },
              itemBuilder: (context, i) => _cardFor(_entries[i]),
            ),
          ),
          if (_entries.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _entries.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? JadalColors.primaryOrange
                          : JadalColors.primaryOrange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardFor(_BannerEntry entry) {
    void onTap() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BackendDebateDetailScreen(
          debateId: entry.debate.id,
          title: entry.debate.title,
        ),
      ),
    );
    // Surface the debate's motion (the actual topic) when one is out — it's
    // far more informative than a generic call-to-action line.
    final motionText = entry.debate.motion?.text.trim();
    final hasMotion = motionText != null && motionText.isNotEmpty;
    switch (entry.kind) {
      case _BannerKind.live:
        return _BannerCard(
          gradient: const [JadalColors.primaryOrange, JadalColors.warmOrange],
          icon: Icons.podcasts_rounded,
          badge: 'LIVE',
          title: entry.debate.title,
          subtitle: hasMotion ? motionText : 'Tap to join the room now',
          onTap: onTap,
        );
      case _BannerKind.registration:
        // Full-opacity palette colors — the old alpha-tinted orange let the
        // page gradient bleed through and read washed-out in both themes.
        // deepBlue → primaryOrange passes right by warmOrange mid-sweep, so
        // the blend stays inside the brand palette.
        return _BannerCard(
          gradient: const [JadalColors.deepBlue, JadalColors.primaryOrange],
          icon: Icons.how_to_reg_rounded,
          badge: 'OPEN',
          title: entry.debate.title,
          subtitle: hasMotion
              ? motionText
              : 'Registration is open — tap to join in',
          onTap: onTap,
        );
      case _BannerKind.done:
        return _BannerCard(
          gradient: const [JadalColors.deepBlue, JadalColors.primaryBlue],
          icon: Icons.emoji_events_rounded,
          badge: 'RESULT',
          title: entry.debate.title,
          subtitle: hasMotion
              ? motionText
              : 'The result is out — tap to see it',
          onTap: onTap,
        );
    }
  }
}

class _BannerCard extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final String? badge;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _BannerCard({
    required this.gradient,
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (badge != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge!,
                              style: AppTextStyles.small(context).copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subtitle(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Smaller than before but allowed a second line — this
                        // is where the motion text lands, and topics rarely
                        // fit on one.
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.small(context).copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
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
