import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';

/// The loading / error / empty placeholders shared by every survey list and
/// detail screen, so a tweak to one applies everywhere instead of drifting
/// screen by screen.
class SurveyLoadingView extends StatelessWidget {
  const SurveyLoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class SurveyErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SurveyErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: JadalColors.judgesGrey,
          ),
          const SizedBox(height: 16),
          Text(
            context.loc.errorWithMessage(message),
            style: AppTextStyles.headline(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: JadalColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(context.loc.retry),
          ),
        ],
      ),
    );
  }
}

/// A centered, muted message — for empty states that aren't inside a
/// pull-to-refresh list (e.g. "no responses yet").
class SurveyEmptyMessage extends StatelessWidget {
  final String message;

  const SurveyEmptyMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.subtitle(
          context,
        ).copyWith(color: JadalColors.judgesGrey),
      ),
    );
  }
}

/// The empty state for a pull-to-refresh survey list: keeps the list
/// scrollable (so refresh still works) while showing a centered message.
class SurveyEmptyState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry padding;

  const SurveyEmptyState({
    super.key,
    required this.message,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: JadalColors.primaryOrange,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          const SizedBox(height: 120),
          SurveyEmptyMessage(message: message),
        ],
      ),
    );
  }
}
