import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/hex_color.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';

/// Read-only list of every motion framework defined in the system (§9 drawer
/// entry) — reuses the same `/motion-frameworks` endpoint the debate search
/// filter dialog (§8) already fetches, rather than a second lookup.
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
        _frameworks = [for (final f in list) (id: f.id, name: f.name, colorHex: f.colorHex)];
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
          title: Text(context.loc.statsFrameworksTitle,
              style: AppTextStyles.title(context).copyWith(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: AppTextStyles.body(context)))
                // §2.7 — a 2-column grid of proper containers instead of the
                // old bare dot-and-title rows; frameworks are a core part of
                // the app and the screen should carry that weight.
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _frameworks.length,
                    itemBuilder: (context, i) {
                      final f = _frameworks[i];
                      final color = colorFromHex(f.colorHex) ?? JadalColors.primaryBlue;
                      return _FrameworkCard(name: f.name, color: color);
                    },
                  ),
      ),
    );
  }
}

/// One framework tile: the framework's color as a tinted icon badge on the
/// app's standard elevated surface, name beneath.
class _FrameworkCard extends StatelessWidget {
  final String name;
  final Color color;
  const _FrameworkCard({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            (dark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface)
                .withValues(alpha: dark ? 0.85 : 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : JadalColors.primaryBlue.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.30 : 0.06),
            blurRadius: 14,
            spreadRadius: -4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.category_rounded, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle(context).copyWith(
              fontWeight: FontWeight.w800,
              color: dark
                  ? JadalColors.darkTextPrimary
                  : JadalColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
