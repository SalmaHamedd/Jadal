import 'package:flutter/material.dart';

/// §2.2 — deterministic initial-avatar colors for users without an image.
///
/// A fixed ramp sweeping from brand blue to brand orange (through violet/rose
/// so every stop stays saturated instead of muddying out). The color is picked
/// by a stable function of the user id, so the same user gets the same color
/// on every reload and on every device — never random-per-render.
///
/// Contrast: every stop is mid-luminance and tested to read clearly against
/// the dark background (0xFF0D1B2E), the light background (0xFFFBF6F0) and the
/// translucent nav surfaces, with white initials on top.
const List<Color> kUserAvatarPalette = [
  Color(0xFF2A63C4), // blue
  Color(0xFF4A5BD0), // indigo
  Color(0xFF7052C8), // violet
  Color(0xFF9349B5), // purple
  Color(0xFFB04A96), // magenta
  Color(0xFFC85A6B), // rose
  Color(0xFFD96A45), // coral
  Color(0xFFE67E22), // orange
];

/// Deterministic palette entry for a numeric user/team id.
Color userAvatarColor(int id) =>
    kUserAvatarPalette[id.abs() % kUserAvatarPalette.length];
