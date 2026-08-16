/// The app's shared visual kit for content surfaces.
///
/// Home and Profile use these instead of inventing their own containers, so
/// every panel shares one corner radius, tonal surface, hairline and entrance
/// motion. Brand blue and orange appear only as small accents — icon badges,
/// values, links — leaving the neutral surfaces to carry the layout in both
/// themes.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Corner radius shared by every elevated surface in the redesigned screens.
const double kJadalRadius = 24;

/// True when the app is in dark mode — every surface tone keys off this.
bool jadalIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color jadalTextPrimary(BuildContext context) => jadalIsDark(context)
    ? JadalColors.darkTextPrimary
    : JadalColors.lightTextPrimary;

Color jadalTextSecondary(BuildContext context) => jadalIsDark(context)
    ? JadalColors.darkTextSecondary
    : JadalColors.lightTextSecondary;

/// The theme-aware replacement for a bare `JadalColors.judgesGrey`
/// used as **text**.
/// `judgesGrey` (#9A9A9A) is tuned for the dark ground, where it measures
/// 5.39:1. On the light ground it is only 2.62:1 — below AA (4.5) and below
/// even the 3:1 non-text floor — so a caption painted with it is genuinely hard
/// to read. This picks the light-ground value (5.02:1) when appropriate and
/// leaves dark theme exactly as it was.
/// Use this for muted TEXT. A grey used purely as an icon tint or a divider is
/// fine as-is.
Color jadalMuted(BuildContext context) => jadalIsDark(context)
    ? JadalColors.judgesGrey
    : JadalColors.judgesGreyLight;

/// A content card: tonal fill over the shared gradient, hairline border and a
/// soft drop shadow. [accent] tints the fill very slightly, which is how a
/// section can feel "warm" or "cool" without painting a saturated block.
class JadalSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final double radius;
  final VoidCallback? onTap;

  const JadalSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.accent,
    this.radius = kJadalRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = jadalIsDark(context);
    final base = dark ? JadalColors.darkSurfaceElevated : JadalColors.lightSurface;
    final tint = accent;
    final radii = BorderRadius.circular(radius);

    final decorated = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: base.withValues(alpha: dark ? 0.88 : 0.94),
        borderRadius: radii,
        border: Border.all(
          color: tint == null
              ? (dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : JadalColors.primaryBlue.withValues(alpha: 0.07))
              : tint.withValues(alpha: dark ? 0.24 : 0.16),
        ),
        // A whisper of the accent as a diagonal wash — enough to differentiate
        // sections, far short of a coloured panel.
        gradient: tint == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    tint.withValues(alpha: dark ? 0.13 : 0.07),
                    base.withValues(alpha: dark ? 0.88 : 0.94),
                  ),
                  base.withValues(alpha: dark ? 0.88 : 0.94),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.34 : 0.07),
            blurRadius: 22,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      borderRadius: radii,
      child: InkWell(borderRadius: radii, onTap: onTap, child: decorated),
    );
  }
}

/// Section title: a small tinted icon badge, the title, and an optional
/// trailing text link. Replaces the bare "text + TextButton" rows that made
/// headings look like loose text floating above content.
class JadalSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  const JadalSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.accent = JadalColors.primaryBlue,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: jadalIsDark(context) ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle(context).copyWith(
              fontWeight: FontWeight.w800,
              color: jadalTextPrimary(context),
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: AppTextStyles.small(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: JadalColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    size: 16,
                    color: JadalColors.primaryOrange,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Staggered fade + rise used by every block on Home and Profile, so a screen
/// assembles itself instead of appearing as one flat slab. [index] shifts the
/// start so blocks cascade; the motion is short and only runs once per mount.
class JadalEntrance extends StatefulWidget {
  final Widget child;
  final int index;

  const JadalEntrance({super.key, required this.child, this.index = 0});

  @override
  State<JadalEntrance> createState() => _JadalEntranceState();
}

class _JadalEntranceState extends State<JadalEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    // Cascade, but cap it so a long screen's last block never feels late.
    final delay = Duration(milliseconds: (widget.index * 70).clamp(0, 420));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

/// Clips a header into a dome: straight sides, flat top, and a bottom edge
/// that bulges downward. Used for the profile cover so it reads as one solid
/// curved mass anchored to the top of the screen rather than a floating strip.
class JadalDomeClipper extends CustomClipper<Path> {
  /// How far the centre of the bottom edge dips below its corners.
  final double depth;
  const JadalDomeClipper({this.depth = 46});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - depth)
      // A single quadratic through the centre gives a clean spherical sweep;
      // the control point is 2× the depth because a quadratic reaches half.
      ..quadraticBezierTo(
        size.width / 2,
        size.height + depth,
        size.width,
        size.height - depth,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant JadalDomeClipper old) => old.depth != depth;
}
