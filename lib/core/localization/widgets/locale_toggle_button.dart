import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_cubit/app_cubit.dart';
import '../../app_cubit/app_states.dart';
import '../../theme/app_text_styles.dart';

class LocaleToggleButton extends StatelessWidget {
  final Color? foregroundColor;
  final Color? backgroundColor;

  const LocaleToggleButton({
    super.key,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = foregroundColor ?? theme.colorScheme.onSurface;
    final bg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (a, b) => a.locale != b.locale,
      builder: (context, state) {
        final showingArabic = state.locale.languageCode == 'ar';
        final label = showingArabic ? 'EN' : 'ع';
        return Material(
          color: bg,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.read<AppCubit>().toggleLocale(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.bodyEmphasis(context).copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
