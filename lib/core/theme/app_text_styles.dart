import 'package:flutter/material.dart';

import '../extensions/responsive_extension.dart';

/// The app's canonical Cairo type scale. Every screen should build its text
/// from one of these instead of hand-rolling `TextStyle(fontFamily: 'Cairo',
/// fontSize: ..., fontWeight: ...)` — that drift (11, 11.5, 12, 12.5, 13,
/// 13.5, 14, 15, 15.5, 16, 17, 19, 24...) is exactly what made text sizing
/// feel inconsistent across the app.
///
/// Each role scales with screen width via [ResponsiveExtension.fontSize]
/// (clamped to a min/max), matching the pattern the auth screens already
/// used — so a tablet doesn't get the same fixed pixel size as a small
/// phone. None of these set a color: pass `.copyWith(color: ...)` for
/// theme-aware (dark/light) or semantic colors.
abstract final class AppTextStyles {
  static const _family = 'Cairo';

  /// Big screen-level title (e.g. the Home tab's "Home"/"جدل" heading, the
  /// app name on auth screens).
  ///
  /// §2.6d — the title roles below sit deliberately far above [body] so a
  /// heading is unmistakably a heading. Only the title end of the scale was
  /// raised; [body] and everything under it keep their sizes so dense
  /// screens (the live debate room, chips, meta rows) keep their density.
  static TextStyle displayTitle(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(26, min: 20, max: 30),
    fontWeight: FontWeight.w800,
  );

  /// Dialog / bottom-sheet / large section headline.
  static TextStyle headline(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(21, min: 17, max: 24),
    fontWeight: FontWeight.w800,
  );

  /// Standard app-bar title.
  static TextStyle title(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(18.5, min: 16, max: 21),
    fontWeight: FontWeight.w800,
  );

  /// Card titles, section headers, list-tile primary text.
  static TextStyle subtitle(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(16, min: 14, max: 18),
    fontWeight: FontWeight.w700,
  );

  /// Default body/paragraph text.
  static TextStyle body(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(13, min: 11.5, max: 15),
    fontWeight: FontWeight.w600,
  );

  /// Body text that needs more weight without changing size (e.g. a value
  /// next to a label, a name in a row).
  static TextStyle bodyEmphasis(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(13, min: 11.5, max: 15),
    fontWeight: FontWeight.w700,
  );

  /// Buttons and other tappable labels.
  static TextStyle button(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(13.5, min: 11, max: 16),
    fontWeight: FontWeight.w700,
  );

  /// Secondary/meta text: timestamps, counts, helper text under a field.
  static TextStyle caption(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(12, min: 10.5, max: 14),
    fontWeight: FontWeight.w600,
  );

  /// Smallest text: chip labels, badges, fine print.
  static TextStyle small(BuildContext context) => TextStyle(
    fontFamily: _family,
    fontSize: context.fontSize(11, min: 9.5, max: 13),
    fontWeight: FontWeight.w600,
  );
}
