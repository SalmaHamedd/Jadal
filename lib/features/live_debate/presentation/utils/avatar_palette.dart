import 'package:flutter/material.dart';

/// Curated bright avatar colours that read well in both light and dark themes
/// (§8.4). Derived from the legacy `profileColors`, trimmed of the muddiest
/// low-contrast entries.
const List<Color> kAvatarPalette = [
  Color(0xFF229F7A), // Teal Green
  Color(0xFF7425D3), // Deep Violet
  Color(0xFF217137), // Forest Green
  Color(0xFFEA8D43), // Sunset Orange
  Color(0xFFA565C5), // Amethyst
  Color(0xFFF1D35F), // Mustard Yellow
  Color(0xFF953943), // Burnt Rose
  Color(0xFFE1653F), // Terracotta
  Color(0xFFDC5F5F), // Coral Red
  Color(0xFFCF3F65), // Raspberry
  Color(0xFF554A8C), // Grape Purple
  Color(0xFF07BC70), // Emerald Green
  Color(0xFF1C61B6), // Royal Blue
  Color(0xFFE36EA4), // Rose Pink
  Color(0xFF5B9CD6), // Blue Gray
];

/// Deterministic colour for a participant: hashing the id means a given person
/// always gets the same colour (fixes the legacy `Random()`-per-build flicker).
Color avatarColorFor(String? id) {
  final key = (id == null || id.isEmpty) ? 'user' : id;
  var hash = 0;
  for (final code in key.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return kAvatarPalette[hash % kAvatarPalette.length];
}

/// First visible character for an avatar fallback (handles empty/whitespace).
String avatarInitial(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.first.toUpperCase();
}
