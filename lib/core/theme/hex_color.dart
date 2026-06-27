import 'package:flutter/material.dart';

Color? colorFromHex(String? hex) {
  if (hex == null) return null;
  var h = hex.trim().replaceAll('#', '');
  if (h.isEmpty) return null;
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final value = int.tryParse(h, radix: 16);
  return value == null ? null : Color(value);
}
