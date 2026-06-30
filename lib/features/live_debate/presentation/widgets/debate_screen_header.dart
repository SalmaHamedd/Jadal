import 'package:flutter/material.dart';

import '../utils/debate_theme.dart';

/// A lightweight in-body header used instead of an AppBar so the page's gradient
/// background runs edge-to-edge with no flat bar on top. Just a back button +
/// title (+ optional trailing actions), painted directly over the background.
class DebateScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  /// Overrides the title/back colour (e.g. a team side colour on the prep room).
  final Color? color;

  const DebateScreenHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? DebateTheme.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back_rounded, color: c),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: c,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
