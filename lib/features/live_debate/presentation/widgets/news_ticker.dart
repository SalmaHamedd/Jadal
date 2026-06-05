import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubits/debate_cubit.dart';
import '../utils/debate_theme.dart';

/// News ticker with a slide + glow on update, recolored to a Jadal blue/orange
/// glow (was lightRed/lightBlue). Behaviour preserved from the legacy
/// `NewsWidget` (§8.3 A).
class NewsTicker extends StatefulWidget {
  const NewsTicker({super.key});

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker> {
  String? _lastNews;
  bool _showGlow = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebateCubit, DebateStates>(
      builder: (context, state) {
        final cubit = context.read<DebateCubit>();
        final dark = DebateTheme.isDark(context);
        final news = cubit.latestNews;

        if (_lastNews != news) {
          _lastNews = news;
          _showGlow = true;
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _showGlow = false);
          });
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 46,
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
                  style: TextStyle(
                    color: DebateTheme.textPrimary(context),
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
