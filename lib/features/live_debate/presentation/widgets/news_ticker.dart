import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubits/debate_controller.dart';
import '../utils/debate_theme.dart';

/// News ticker with a slide + glow on update, recolored to a Jadal blue/orange
/// glow (was lightRed/lightBlue). Behaviour preserved from the legacy
/// `NewsWidget`.
class NewsTicker extends StatefulWidget {
  const NewsTicker({super.key});

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker> {
  String? _lastNews;
  bool _showGlow = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebateController, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateController>();
        final dark = DebateTheme.isDark(context);
        // The ticker is never empty. Before any news arrives, show a calm line —
        // but if the debate is already live (a mid-debate joiner / the chair just
        // moved to the live session) the "hasn't started yet" line is misleading,
        // so show "you've joined the live session" instead.
        final raw = cubit.latestNews;
        final news = raw.isNotEmpty
            ? raw
            : (cubit.debateStarted
                ? context.loc.youJoinedLiveSession
                : context.loc.debateNotStarted);

        if (!_initialized) {
          // First open: seed the baseline WITHOUT the glow. The slide+glow should
          // only fire when the news *changes while we're watching* — not just
          // because the screen was opened.
          _initialized = true;
          _lastNews = news;
        } else if (_lastNews != news) {
          _lastNews = news;
          _showGlow = true;
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _showGlow = false);
          });
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 44,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widgetBorderRadius),
            boxShadow: _showGlow
                ? [
                    BoxShadow(
                      color: JadalColors.primaryBlue.withValues(alpha: 0.55),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                    ),
                    BoxShadow(
                      color: JadalColors.primaryOrange.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widgetBorderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DebateTheme.surfaceElevated(context),
                border: Border.all(
                  color: JadalColors.primaryBlue.withValues(alpha: dark ? 0.30 : 0.18),
                ),
                borderRadius: BorderRadius.circular(widgetBorderRadius),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  final isNew = child.key == ValueKey(news);
                  final offset = Tween<Offset>(
                    begin: isNew ? const Offset(0, 1.2) : const Offset(0, -1.2),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(position: offset, child: child);
                },
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  children: [...previous, ?current],
                ),
                child: Text(
                  news,
                  key: ValueKey<String>(news),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body(context)
                      .copyWith(color: DebateTheme.textPrimary(context), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
