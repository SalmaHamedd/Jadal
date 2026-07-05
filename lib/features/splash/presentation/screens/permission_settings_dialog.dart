import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../data/permissions_service.dart';

/// Shows a frosted-glass dialog telling the user which permissions
/// are permanently denied and offers a direct path to app settings.
///
/// Usage:
///   PermissionSettingsDialog.show(context, denied: result.denied);
class PermissionSettingsDialog extends StatelessWidget {
  final List<AppPermission> denied;

  const PermissionSettingsDialog({super.key, required this.denied});

  static Future<void> show(
      BuildContext context, {
        required List<AppPermission> denied,
      }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      barrierDismissible: false,
      builder: (_) => PermissionSettingsDialog(denied: denied),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = context.loc;

    final cardBg =
    isDark ? JadalColors.darkBackground : JadalColors.lightSurface;
    final textPrimary =
    isDark ? JadalColors.darkTextPrimary : JadalColors.deepBlue;
    final textSecondary =
    isDark ? JadalColors.darkTextSecondary : JadalColors.lightTextSecondary;
    final accent =
    isDark ? const Color(0xFFF59A4A) : JadalColors.primaryOrange;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg.withValues(alpha: isDark ? 0.92 : 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: isDark ? 48 : 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon badge ──────────────────────────────────────────
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: accent,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),

                // ── Title ───────────────────────────────────────────────
                Text(
                  loc.permissionsRequiredTitle, // "Permissions Required"
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: context.fontSize(19, min: 16, max: 22),
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Subtitle ────────────────────────────────────────────
                Text(
                  loc.permissionsRequiredBody,
                  // "Some permissions were denied. Enable them in Settings
                  //  to use all features of Jadal."
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: context.fontSize(13, min: 11, max: 14),
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),

                // ── Denied permission chips ──────────────────────────────
                if (denied.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.18),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: denied
                          .map((p) => _PermissionRow(
                        permission: p,
                        accent: accent,
                        textPrimary: textPrimary,
                        loc: loc,
                        isLast: p == denied.last,
                        dividerColor: dividerColor,
                      ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Open Settings button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await PermissionsService().openAppSettingsPage();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.settings_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          loc.openSettings, // "Open Settings"
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Skip / dismiss ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      loc.skipForNow, // "Skip for now"
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: context.fontSize(13, min: 11, max: 14),
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Individual permission row inside the chip box ──────────────────────────

class _PermissionRow extends StatelessWidget {
  final AppPermission permission;
  final Color accent;
  final Color textPrimary;
  final dynamic loc; // your AppLocalizations type
  final bool isLast;
  final Color dividerColor;

  const _PermissionRow({
    required this.permission,
    required this.accent,
    required this.textPrimary,
    required this.loc,
    required this.isLast,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (permission) {
      AppPermission.camera =>
      (Icons.camera_alt_outlined, loc.permissionCamera),  // "Camera"
      AppPermission.microphone =>
      (Icons.mic_outlined, loc.permissionMicrophone),      // "Microphone"
      AppPermission.bluetooth =>
      (Icons.bluetooth_outlined, loc.permissionBluetooth), // "Bluetooth"
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.cancel_outlined,
                color: accent.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }
}