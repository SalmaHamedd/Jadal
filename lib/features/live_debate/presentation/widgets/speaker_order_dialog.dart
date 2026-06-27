import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
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

  /// FE-8: the number of speaking slots to offer (= speakers per side), so a
  /// 2-person team can still fill a 3rd slot (duplicates allowed). Defaults to
  /// the roster size when not provided.
  final int? slotCount;
  final void Function(List<String> ordered, String? replySpeakerId) onConfirm;

  const SpeakerOrderDialog({
    super.key,
    required this.team,
    required this.current,
    required this.replyEnabled,
    this.slotCount,
    required this.onConfirm,
  });

  @override
  State<SpeakerOrderDialog> createState() => _SpeakerOrderDialogState();
}

class _SpeakerOrderDialogState extends State<SpeakerOrderDialog> {
  late List<String> _ordered;
  // FE-8: the DISTINCT debaters for the per-slot dropdown — `team.debaters` is N
  // fixed slots that may repeat a debater (multi-role), so the dropdown's item
  // list must be de-duplicated (a DropdownButton requires unique item values).
  late List<Debater> _roster;
  String? _replyId;

  @override
  void initState() {
    super.initState();
    final seen = <String>{};
    _roster = [
      for (final d in widget.team.debaters)
        if (d.id.isNotEmpty && seen.add(d.id)) d,
    ];
    final rosterIds = _roster.map((d) => d.id).toSet();
    final fallback = _roster.isNotEmpty ? _roster.first.id : '';
    // FE-7/8: exactly N slots (= team speeches per side), duplicates allowed. Seed
    // from the saved order, else from the slot defaults; coerce any invalid slot
    // to a real debater so the dropdown value is always a valid item.
    final n = (widget.slotCount != null && widget.slotCount! > 0)
        ? widget.slotCount!
        : widget.team.debaters.length;
    final base = widget.current.orderedSpeakerIds.isNotEmpty
        ? List.of(widget.current.orderedSpeakerIds)
        : widget.team.debaters.map((d) => d.id).toList();
    _ordered = [
      for (var i = 0; i < n; i++)
        (i < base.length && rosterIds.contains(base[i])) ? base[i] : fallback,
    ];
    if (widget.replyEnabled) {
      final allowed = _ordered.take(2).toList();
      _replyId = (widget.current.replySpeakerId != null &&
              allowed.contains(widget.current.replySpeakerId))
          ? widget.current.replySpeakerId
          : (allowed.isNotEmpty ? allowed.first : null);
    }
  }

  void _setSlot(int index, String id) {
    setState(() {
      _ordered[index] = id;
      // Keep the reply speaker valid (must be one of the first two speakers).
      if (widget.replyEnabled && !_ordered.take(2).contains(_replyId)) {
        _replyId = _ordered.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    final teamColor = DebateTheme.sideColor(widget.team.side);
    // The reply can be either of the first two speakers (de-duplicated, since the
    // same debater may fill both slots).
    final replyChoices = <String>{..._ordered.take(2)}.toList();
    return JadalDialog(
      width: size.width * 0.9,
      height: size.height * 0.72,
      firstColor: teamColor,
      secondColor: Color.lerp(teamColor, Colors.black, 0.20)!,
      bodyColor: DebateTheme.surface(context),
      icon: Icons.format_list_numbered_rounded,
      title: loc.speakerOrderTitle,
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.selectSpeakerOrder,
                style: TextStyle(
                    fontFamily: 'Cairo', color: DebateTheme.textSecondary(context), fontSize: 12)),
            const SizedBox(height: 8),
            Expanded(
              child: _roster.isEmpty
                  ? Center(
                      child: Text(loc.notJoinedYet,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              color: DebateTheme.textSecondary(context))),
                    )
                  : ListView(
                      children: [
                        for (var i = 0; i < _ordered.length; i++) _slotRow(context, i),
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
                  for (final id in replyChoices)
                    ChoiceChip(
                      label: Text(widget.team.debaterById(id)?.name ?? '—',
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

  /// One speaking turn: a P1/O2… badge + a dropdown to pick which debater fills
  /// it. The same debater may be chosen for more than one turn (handled by the
  /// live room as a multi-role speaker).
  Widget _slotRow(BuildContext context, int index) {
    final side = widget.team.side;
    final sideColor = DebateTheme.sideColor(side);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsetsDirectional.only(start: 12, top: 6, bottom: 6, end: 10),
      decoration: BoxDecoration(
        color: DebateTheme.surfaceElevated(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sideColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: sideColor,
            child: Text('${side.rolePrefix}${index + 1}',
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _ordered[index],
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: DebateTheme.surfaceElevated(context),
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: DebateTheme.textPrimary(context)),
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: DebateTheme.textSecondary(context)),
                items: [
                  for (final d in _roster)
                    DropdownMenuItem<String>(
                      value: d.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: avatarColorFor(d.id),
                            child: Text(avatarInitial(d.name),
                                style: const TextStyle(
                                    color: Colors.white, fontFamily: 'Cairo', fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(d.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: DebateTheme.textPrimary(context))),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) _setSlot(index, v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
