import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_dialog.dart';
import '../../../../core/widgets/jadal_gradient_button.dart';
import '../../data/models/debate_models.dart';
import '../utils/avatar_palette.dart';
import '../utils/debate_theme.dart';

/// Speaker-order selection used by the current leader during prep (§8.1):
/// drag-to-reorder the three speakers + (if reply is on) pick the reply speaker
/// constrained to the 1st or 2nd speaker. Confirms with a gradient button.
class SpeakerOrderDialog extends StatefulWidget {
  final TeamInfo team;
  final SpeakerOrder current;
  final bool replyEnabled;
  final void Function(List<String> ordered, String? replySpeakerId) onConfirm;

  const SpeakerOrderDialog({
    super.key,
    required this.team,
    required this.current,
    required this.replyEnabled,
    required this.onConfirm,
  });

  @override
  State<SpeakerOrderDialog> createState() => _SpeakerOrderDialogState();
}

class _SpeakerOrderDialogState extends State<SpeakerOrderDialog> {
  late List<String> _ordered;
  String? _replyId;

  @override
  void initState() {
    super.initState();
    _ordered = widget.current.orderedSpeakerIds.isNotEmpty
        ? List.of(widget.current.orderedSpeakerIds)
        : widget.team.debaters.map((d) => d.id).toList();
    if (widget.replyEnabled) {
      final allowed = _ordered.take(2).toList();
      _replyId = (widget.current.replySpeakerId != null &&
              allowed.contains(widget.current.replySpeakerId))
          ? widget.current.replySpeakerId
          : allowed.first;
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final id = _ordered.removeAt(oldIndex);
      _ordered.insert(newIndex, id);
      // Keep the reply speaker valid (1st or 2nd only).
      if (widget.replyEnabled && !_ordered.take(2).contains(_replyId)) {
        _replyId = _ordered.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    return JadalDialog(
      width: size.width * 0.9,
      height: size.height * 0.72,
      firstColor: DebateTheme.sideColor(widget.team.side),
      secondColor: JadalColors.primaryOrange,
      bodyColor: DebateTheme.surface(context),
      title: loc.speakerOrderTitle,
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dragToReorder,
                style: TextStyle(
                    fontFamily: 'Cairo', color: DebateTheme.textSecondary(context), fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: true,
                onReorder: _onReorder,
                children: [
                  for (var i = 0; i < _ordered.length; i++)
                    _orderTile(context, i, widget.team.debaterById(_ordered[i])!),
                ],
              ),
            ),
            if (widget.replyEnabled) ...[
              const SizedBox(height: 8),
              Text(loc.replySpeaker,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      color: DebateTheme.textPrimary(context))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final id in _ordered.take(2))
                    ChoiceChip(
                      label: Text(widget.team.debaterById(id)!.name,
                          style: const TextStyle(fontFamily: 'Cairo')),
                      selected: _replyId == id,
                      onSelected: (_) => setState(() => _replyId = id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            JadalGradientButton(
              text: loc.saveOrder,
              icon: Icons.check_rounded,
              onPressed: () {
                widget.onConfirm(_ordered, widget.replyEnabled ? _replyId : null);
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(BuildContext context, int index, Debater d) {
    final side = widget.team.side;
    return Container(
      key: ValueKey(d.id),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsetsDirectional.only(start: 12, top: 8, bottom: 8, end: 8),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DebateTheme.sideColor(side).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: DebateTheme.sideColor(side),
            child: Text('${side.rolePrefix}${index + 1}',
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 14,
            backgroundColor: avatarColorFor(d.id),
            child: Text(avatarInitial(d.name),
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              d.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: DebateTheme.textPrimary(context)),
            ),
          ),
          Icon(Icons.drag_handle_rounded, color: DebateTheme.textSecondary(context)),
        ],
      ),
    );
  }
}
