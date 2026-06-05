import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_cubit/app_cubit.dart';
import '../../app_cubit/app_states.dart';

class ThemeToggleButton extends StatelessWidget {
  final Color? foregroundColor;

  const ThemeToggleButton({super.key, this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, state) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final isDark = state.themeMode == ThemeMode.dark ||
            (state.themeMode == ThemeMode.system &&
                platformBrightness == Brightness.dark);
        final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
        return IconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          onPressed: () =>
              context.read<AppCubit>().toggleTheme(platformBrightness),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              color: color,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}
