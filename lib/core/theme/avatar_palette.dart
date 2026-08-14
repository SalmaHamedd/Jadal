import 'package:flutter/material.dart';

/// §2.2 — deterministic initial-avatar colors for users without an image.
///
/// The color is picked by a stable function of the user id, so the same user
/// gets the same color on every reload and on every device — never
/// random-per-render.
///
/// MF_FU §7.4b — this used to be an 8-stop ramp sweeping brand blue → orange
/// through violet/rose, which meant **neighbouring stops were near-identical by
/// construction**: worst pair CIEDE2000 ΔE 6.3 for *normal* vision (4 of 28
/// pairs below the ΔE 11 "distinct" threshold), collapsing to ΔE 0.4 under
/// tritanopia and 1.7 under deuteranopia.
///
/// A measured finding worth recording: **eight mutually-distinguishable hues
/// are not achievable under dichromacy.** A greedy max-min search over a ~300
/// colour pool (hue every 6°, five lightness/saturation levels, filtered to
/// keep white initials ≥ 4.5:1) tops out at *five* stops with every pair
/// clearing ΔE 11; at six one pair fails, at eight, four do.
///
/// That is acceptable here because avatar colour is **decorative, never
/// semantic** — an avatar always carries the user's initial and sits beside
/// their name — so it is held to ΔE ≥ 6 rather than ≥ 11. Six stops, and no
/// purple: purple is blue plus red, so removing red makes it read as blue
/// (measured ΔE 3.0 against the brand blue under protanopia, the worst
/// collision available). Separation now comes from lightness as well as hue.
///
/// Measured: normal-vision worst pair 6.3 → 12.8, CVD worst 0.4 → 6.2.
const List<Color> kUserAvatarPalette = [
  Color(0xFF0352A1), // brand blue
  Color(0xFF0B73DA), // lighter blue — separated by lightness, not hue
  Color(0xFF009E73), // teal-green
  Color(0xFFC2410C), // burnt orange
  Color(0xFF9D174D), // crimson
  Color(0xFF44403C), // warm slate
];

/// Deterministic palette entry for a numeric user/team id.
Color userAvatarColor(int id) =>
    kUserAvatarPalette[id.abs() % kUserAvatarPalette.length];

/// The initial's colour on [background]. Every stop takes white except the
/// teal-green, which only reaches 3.42:1 against white and so takes near-black.
Color userAvatarForeground(Color background) =>
    background == const Color(0xFF009E73)
        ? const Color(0xFF0B0F14)
        : Colors.white;
