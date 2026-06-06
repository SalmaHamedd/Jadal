import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// Styled dialog shell used across the live-debate feature (§3.4).
///
/// Mirrors the `CustomDialog(width, height, firstColor, secondColor, bodyColor,
/// title, body)` contract the legacy `call` feature referenced (that file does
/// not exist in this project), re-skinned with the Jadal palette. The header is
/// a [firstColor]→[secondColor] gradient; the body sits on [bodyColor].
class JadalDialog extends StatelessWidget {
  final double width;
  final double height;
  final Color firstColor;
  final Color secondColor;
  final Color bodyColor;
  final String title;
  final Widget body;
  final bool showClose;

  const JadalDialog({
    super.key,
    required this.width,
    required this.height,
    required this.firstColor,
    required this.secondColor,
    required this.bodyColor,
    required this.title,
    required this.body,
    this.showClose = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widgetBorderRadius),
        child: Container(
          width: width,
          height: height,
          color: bodyColor,
          child: Column(
            children: [
              // Gradient header.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [firstColor, secondColor],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (showClose)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
