import 'package:flutter/material.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/team_membership.dart';

/// Current teams for a user, with a "show history" button that expands the
/// past-memberships list in place (§6.4). Renders nothing if there are no
/// current teams AND the caller hasn't asked to see history.
class TeamMembershipSection extends StatefulWidget {
  final int userId;
  final List<TeamMembership> current;
  const TeamMembershipSection({super.key, required this.userId, required this.current});

  @override
  State<TeamMembershipSection> createState() => _TeamMembershipSectionState();
}

class _TeamMembershipSectionState extends State<TeamMembershipSection> {
  final ProfileRepository _repo = ProfileRepository();
  List<TeamMembership>? _history;
  bool _loadingHistory = false;

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final res = await _repo.getUserTeams(widget.userId, history: true);
    res.fold(
      (f) => setState(() {
        _history = const [];
        _loadingHistory = false;
      }),
      (items) => setState(() {
        _history = items;
        _loadingHistory = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary;
    if (widget.current.isEmpty && _history == null) {
      return TextButton.icon(
        onPressed: _loadingHistory ? null : _loadHistory,
        icon: const Icon(Icons.history, size: 16),
        label: const Text('Show team history', style: TextStyle(fontFamily: 'Cairo')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in widget.current) _TeamTile(membership: t, textColor: textColor),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _loadingHistory
                ? null
                : (_history == null ? _loadHistory : () => setState(() => _history = null)),
            icon: Icon(_history == null ? Icons.history : Icons.expand_less, size: 16),
            label: Text(
              _history == null ? 'Show team history' : 'Hide history',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ),
        if (_loadingHistory)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (_history != null && !_loadingHistory)
          if (_history!.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('No past teams', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
            )
          else
            for (final t in _history!) _TeamTile(membership: t, textColor: textColor, past: true),
      ],
    );
  }
}

class _TeamTile extends StatelessWidget {
  final TeamMembership membership;
  final Color textColor;
  final bool past;
  const _TeamTile({required this.membership, required this.textColor, this.past = false});

  String _elapsed() {
    final start = membership.joinedAt;
    if (start == null) return '';
    final end = membership.leftAt ?? DateTime.now();
    final days = end.difference(start).inDays;
    if (days < 30) return '$days d';
    if (days < 365) return '${(days / 30).round()} mo';
    return '${(days / 365).round()} yr';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.groups_rounded, size: 16, color: past ? JadalColors.judgesGrey : JadalColors.primaryOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              membership.teamName,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: past ? JadalColors.judgesGrey : textColor,
              ),
            ),
          ),
          Text(
            _elapsed(),
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: JadalColors.judgesGrey),
          ),
        ],
      ),
    );
  }
}
