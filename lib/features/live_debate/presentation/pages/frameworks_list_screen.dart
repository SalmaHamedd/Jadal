import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/hex_color.dart';
import 'package:jadal_app/core/error/failure_text.dart';
import 'package:jadal_app/core/widgets/jadal_error_view.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/presentation/utils/debate_theme.dart';

/// Read-only list of every motion framework defined in the system (drawer
/// entry) — reuses the same `/motion-frameworks` endpoint the debate search
/// filter dialog already fetches, rather than a second lookup.
class FrameworksListScreen extends StatefulWidget {
  const FrameworksListScreen({super.key});

  @override
  State<FrameworksListScreen> createState() => _FrameworksListScreenState();
}

class _FrameworksListScreenState extends State<FrameworksListScreen> {
  bool _loading = true;
  String? _error;
  List<({int id, String name, String? colorHex})> _frameworks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await di.sl<LiveDebateRepository>().getMotionFrameworks();
    if (!mounted) return;
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (list) => setState(() {
        _frameworks = [
          for (final f in list) (id: f.id, name: f.name, colorHex: f.colorHex),
        ];
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
            context.loc.statsFrameworksTitle,
            style: AppTextStyles.title(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            // Printed the raw failure string before — that is where a
            // transport exception showed up on screen.
            : _error != null
            ? JadalErrorScrollView(
                message: FailureText.fromMessage(context, _error),
                onRetry: _load,
              )
            // A grid of proper containers instead of the old bare
            // dot-and-title rows; frameworks are a core part of the app and
            // the screen should carry that weight.
            // The old fixed 2-column / 1.5-aspect grid gave
            // each tile a hard height that a long (often Arabic) framework
            // name overflowed. maxCrossAxisExtent lets wide screens go to
            // three columns instead of stretching two, and mainAxisExtent
            // sizes the tile for the banner + label rather than by ratio.
            : RefreshIndicator(
                color: JadalColors.primaryOrange,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // A short lead-in so the screen opens with a sentence
                    // rather than dropping straight into a bare grid — the
                    // grid alone read as a list of unexplained labels.
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: JadalColors.primaryOrange.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_library_rounded,
                                size: 20,
                                color: JadalColors.primaryOrange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.loc.frameworksCount(_frameworks.length),
                                style: AppTextStyles.caption(context).copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: DebateTheme.textSecondary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisExtent: 158,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final f = _frameworks[i];
                          final color =
                              colorFromHex(f.colorHex) ??
                              JadalColors.primaryBlue;
                          return _FrameworkCard(
                            name: f.name,
                            color: color,
                            index: i,
                          );
                        }, childCount: _frameworks.length),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// One framework tile: a muted banner in the framework's own colour
/// carrying the icon, and the name on the standard elevated surface beneath.
/// The name scales down to fit rather than overflowing its fixed tile height.
class _FrameworkCard extends StatelessWidget {
  final String name;
  final Color color;
  final int index;
  const _FrameworkCard({
    required this.name,
    required this.color,
    this.index = 0,
  });

  static const double _bannerHeight = 58;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        (dark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface)
            .withValues(alpha: dark ? 0.85 : 0.92);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.06),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : JadalColors.primaryBlue.withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Muted banner — deliberately low-saturation so a grid of them
              // reads as a set, not a box of highlighters. The soft diagonal
              // and the oversized watermark glyph give each tile some depth
              // instead of a flat colour block.
              SizedBox(
                height: _bannerHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                            colors: [
                              color.withValues(alpha: dark ? 0.30 : 0.20),
                              color.withValues(alpha: dark ? 0.14 : 0.08),
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: color.withValues(alpha: 0.30),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Watermark: clipped by the card, reads as texture.
                    PositionedDirectional(
                      end: -10,
                      top: -6,
                      child: Icon(
                        Icons.format_quote_rounded,
                        size: 62,
                        color: color.withValues(alpha: dark ? 0.16 : 0.12),
                      ),
                    ),
                    PositionedDirectional(
                      start: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_library_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: dark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
