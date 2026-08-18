import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/avatar_palette.dart';

/// A participant's face: their profile picture when they have one, otherwise the
/// deterministic coloured initial the rooms have always used.
///
/// The fallback also covers a picture that is still loading or failed to load —
/// a spinner or a grey box inside a 24px circle reads as breakage, whereas the
/// initial reads as a person.
class ParticipantAvatar extends StatelessWidget {
  /// Drives the fallback colour, so a given person always gets the same one.
  final String participantId;

  /// Drives the fallback initial.
  final String name;

  final String? avatarUrl;
  final double diameter;

  /// Font size for the fallback initial; defaults to a proportion of [diameter].
  final double? initialFontSize;

  const ParticipantAvatar({
    super.key,
    required this.participantId,
    required this.name,
    required this.avatarUrl,
    required this.diameter,
    this.initialFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final fallback = _initial(context);
    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }

  Widget _initial(BuildContext context) => Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatarColorFor(participantId),
        ),
        alignment: Alignment.center,
        child: Text(
          avatarInitial(name),
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: initialFontSize ?? diameter * 0.42,
          ),
        ),
      );
}
