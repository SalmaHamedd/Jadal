import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/repositories/live_debate_repository.dart';
import '../../domain/debate_registration.dart';
import '../utils/debate_theme.dart';

/// Registration entry (§15.1): pick team / solo / judge and POST to
/// `/debates/{id}/register`. Team registration needs the caller's team id (the
/// caller must be that team's leader or coach). Resolves to `true` when the
/// registration succeeds so the caller can refresh. [rootContext] carries the
/// snackbar after the sheet closes.
Future<bool?> showRegistrationSheet(BuildContext rootContext, int debateId) {
  return showModalBottomSheet<bool>(
    context: rootContext,
    backgroundColor: DebateTheme.surface(rootContext),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RegistrationSheet(debateId: debateId, rootContext: rootContext),
  );
}

class _RegistrationSheet extends StatefulWidget {
  final int debateId;
  final BuildContext rootContext;
  const _RegistrationSheet({required this.debateId, required this.rootContext});

  @override
  State<_RegistrationSheet> createState() => _RegistrationSheetState();
}

class _RegistrationSheetState extends State<_RegistrationSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: DebateTheme.textSecondary(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              loc.registerTitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: DebateTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else ...[
              _option(context, Icons.groups_rounded, loc.registerAsTeam, RegistrationKind.team),
              _option(context, Icons.person_rounded, loc.registerAsSolo, RegistrationKind.solo),
              _option(context, Icons.gavel_rounded, loc.registerAsJudge, RegistrationKind.judge),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, IconData icon, String label, RegistrationKind kind) {
    return ListTile(
      leading: Icon(icon, color: JadalColors.primaryBlue),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
          color: DebateTheme.textPrimary(context),
        ),
      ),
      onTap: () => _choose(kind),
    );
  }

  Future<void> _choose(RegistrationKind kind) async {
    int? teamId;
    if (kind == RegistrationKind.team) {
      // The team variant needs a team id; the caller must be its leader/coach.
      teamId = await _askTeamId();
      if (teamId == null) return; // cancelled
    }
    await _submit(kind, teamId);
  }

  Future<int?> _askTeamId() async {
    final loc = context.loc;
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: DebateTheme.surface(dctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.registerAsTeam, style: const TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.teamRegisterPrompt,
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 12, color: DebateTheme.textSecondary(dctx)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontFamily: 'Cairo', color: DebateTheme.textPrimary(dctx)),
              decoration: InputDecoration(
                labelText: loc.teamIdLabel,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              final id = int.tryParse(controller.text.trim());
              if (id != null) Navigator.of(dctx).pop(id);
            },
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(RegistrationKind kind, int? teamId) async {
    setState(() => _busy = true);
    final repo = di.sl<LiveDebateRepository>();
    final res = await repo.register(
      DebateRegistration(debateId: widget.debateId, kind: kind, teamId: teamId),
    );
    if (!mounted) return;
    Navigator.of(context).pop(res.isRight());
    if (!widget.rootContext.mounted) return;
    res.fold(
      (f) => JadalSnackBar.show(widget.rootContext, f.message, type: SnackBarType.error),
      (msg) => JadalSnackBar.show(widget.rootContext, msg, type: SnackBarType.success),
    );
  }
}
