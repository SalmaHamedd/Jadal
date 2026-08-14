import 'package:flutter/material.dart';

import '../localization/l10n/context_localiztion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'jadal_surface.dart';

/// The app's ONE retry control: a reload icon on a soft orange plate.
///
/// Screens used to each roll their own — an `OutlinedButton.icon` here, a
/// bare `ElevatedButton` with no padding there — so a failed load looked
/// different (and worse) depending on where you hit it.
class JadalRetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final double size;

  const JadalRetryButton({super.key, required this.onRetry, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final dark = jadalIsDark(context);
    return Semantics(
      button: true,
      label: context.loc.retry,
      child: Material(
        color: JadalColors.primaryOrange.withValues(alpha: dark ? 0.22 : 0.14),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onRetry,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.refresh_rounded,
              size: size * 0.46,
              color: JadalColors.primaryOrange,
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's ONE failed-load state: an icon, a human-readable message, and a
/// [JadalRetryButton].
///
/// Always pass a message that has already been through `FailureText` — this
/// widget renders exactly what it is given, so a raw exception string handed
/// to it will be shown to the user.
class JadalErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// Sits inside an existing card/section rather than filling a screen, so it
  /// drops the outer surface and tightens the spacing.
  final bool compact;

  /// Overrides the leading glyph. Defaults to a "no connection" cloud, which
  /// is the overwhelmingly common cause.
  final IconData icon;

  const JadalErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 46 : 60,
          height: compact ? 46 : 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: JadalColors.judgesGrey.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: compact ? 24 : 30,
            color: jadalTextSecondary(context),
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body(
            context,
          ).copyWith(color: jadalTextPrimary(context), height: 1.45),
        ),
        SizedBox(height: compact ? 12 : 18),
        JadalRetryButton(onRetry: onRetry, size: compact ? 44 : 52),
      ],
    );

    // Generous padding on purpose: the old retry buttons sat flush against
    // their text with none at all.
    final padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 32,
        vertical: compact ? 18 : 28,
      ),
      child: body,
    );

    if (compact) return Center(child: padded);
    return Center(child: SingleChildScrollView(child: padded));
  }
}

/// [JadalErrorView] inside a scrollable, so a failed screen can still be
/// pulled down to retry. Use where the success state is itself a list.
class JadalErrorScrollView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final IconData icon;

  const JadalErrorScrollView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: JadalColors.primaryOrange,
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.16),
          JadalErrorView(
            message: message,
            icon: icon,
            onRetry: () => onRetry(),
          ),
        ],
      ),
    );
  }
}
