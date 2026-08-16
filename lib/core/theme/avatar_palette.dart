import 'package:flutter/material.dart';

/// Deterministic initial-avatar colours for users without an image.
///
/// The colour is a stable function of the user id, so the same user keeps the
/// same colour across reloads and devices.
///
/// Six stops, not eight: more than about five hues cannot stay distinguishable
/// under colour-blindness, and the old blue→orange ramp collapsed to nearly
/// identical neighbours. Purple is left out because without red it reads as the
/// brand blue. Separation comes from lightness as well as hue.
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
