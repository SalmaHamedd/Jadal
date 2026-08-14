import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_snack_bar.dart';
import '../../../../di/injection_container.dart' as di;
import '../../data/models/registration_models.dart';
import '../../data/repositories/live_debate_repository.dart';
import '../../domain/debate_registration.dart';
import '../utils/debate_theme.dart';
import '../../../../core/error/failure_text.dart';

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
  /// Which action is mid-flight (spinner shows *inside* that button so the sheet
  /// never reflows / shrinks — the old whole-content swap was the "weird shrink").
  RegistrationKind? _submitting;

  /// Resolving the role-gated option set on open.
  bool _resolving = true;
  bool _showTeam = false;
  bool _showJudge = false;
  bool _showSolo = true;

  @override
  void initState() {
    super.initState();
    _resolveOptions();
  }

  /// The visible options depend on the caller's account role (§UX):
  ///  • judge   → Register as Judge ONLY (§5.4 — a judge can never go solo)
  ///  • trainer → Register your Team (+ Solo)
  ///  • debater → Solo; plus Team **only if they lead a registerable team**
  ///  • unknown/legacy session (role not cached) → be permissive: show all.
  Future<void> _resolveOptions() async {
    final role = (await TokenStorage.getRole())?.toLowerCase();
    var showTeam = false;
    var showJudge = false;
    var showSolo = true;
    switch (role) {
      case 'judge':
        showJudge = true;
        showSolo = false;
      case 'trainer':
      case 'coach':
        showTeam = true;
      case 'debater':
        // A debater only leads (never coaches) teams, so a non-empty
        // registerable-teams list means they're a team leader here.
        final res =
            await di.sl<LiveDebateRepository>().getRegisterableTeams(widget.debateId);
        showTeam = res.fold((_) => false, (r) => r.teams.isNotEmpty);
      default:
        // No cached role → don't hide anything.
        showTeam = true;
        showJudge = true;
    }
    if (!mounted) return;
    setState(() {
      _showTeam = showTeam;
      _showJudge = showJudge;
      _showSolo = showSolo;
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: DebateTheme.textSecondary(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              loc.registerTitle,
              style: AppTextStyles.title(context)
                  .copyWith(color: DebateTheme.textPrimary(context)),
            ),
            const SizedBox(height: 16),
            if (_resolving)
              const SizedBox(
                height: 76,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              )
            else ...[
              if (_showTeam)
                _actionButton(
                  context,
                  icon: Icons.groups_rounded,
                  label: loc.registerAsTeam,
                  color: JadalColors.primaryBlue,
                  kind: RegistrationKind.team,
                  onTap: _onTeam,
                ),
              if (_showSolo)
                _actionButton(
                  context,
                  icon: Icons.person_rounded,
                  label: loc.registerAsSolo,
                  color: JadalColors.deepBlue,
                  kind: RegistrationKind.solo,
                  onTap: () => _submit(RegistrationKind.solo, null),
                ),
              if (_showJudge)
                _actionButton(
                  context,
                  icon: Icons.gavel_rounded,
                  label: loc.registerAsJudge,
                  color: JadalColors.primaryOrange,
                  kind: RegistrationKind.judge,
                  onTap: () => _submit(RegistrationKind.judge, null),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// A full-width brand button. When [kind] is mid-flight it swaps its icon for a
  /// spinner and every button disables — the footprint stays fixed.
  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required RegistrationKind kind,
    required VoidCallback onTap,
  }) {
    final loading = _submitting == kind;
    final anyBusy = _submitting != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: anyBusy ? null : onTap,
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(alpha: 0.5),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Icon(icon),
          label: Text(
            label,
            style: AppTextStyles.button(context).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Future<void> _onTeam() async {
    // Show the spinner on the team button across both the pick and the submit.
    setState(() => _submitting = RegistrationKind.team);
    final teamId = await _pickTeam();
    if (teamId == null) {
      if (mounted) setState(() => _submitting = null); // cancelled / none / error
      return;
    }
    await _submit(RegistrationKind.team, teamId);
  }

  /// Fetches the teams the caller may register for this debate and lets them pick
  /// one (ineligible teams are shown disabled with the reason).
  Future<int?> _pickTeam() async {
    final res = await di.sl<LiveDebateRepository>().getRegisterableTeams(widget.debateId);
    if (!mounted) return null;

    final failure = res.fold((l) => l, (_) => null);
    if (failure != null) {
      if (widget.rootContext.mounted) {
        JadalSnackBar.show(widget.rootContext, FailureText.fromMessage(widget.rootContext, failure.message), type: SnackBarType.error);
      }
      return null;
    }
    final data = res.fold((_) => null, (r) => r)!;
    if (data.teams.isEmpty) {
      JadalSnackBar.show(context, 'No teams you can register for this debate.',
          type: SnackBarType.warning);
      return null;
    }
    if (!mounted) return null;
    return showDialog<int>(
      context: context,
      builder: (_) => _TeamPickerDialog(data: data),
    );
  }

  Future<void> _submit(RegistrationKind kind, int? teamId) async {
    setState(() => _submitting = kind);
    final repo = di.sl<LiveDebateRepository>();
    final res = await repo.register(
      DebateRegistration(debateId: widget.debateId, kind: kind, teamId: teamId),
    );
    if (!mounted) return;
    Navigator.of(context).pop(res.isRight());
    if (!widget.rootContext.mounted) return;
    res.fold(
      (f) => JadalSnackBar.show(widget.rootContext, FailureText.fromMessage(widget.rootContext, f.message), type: SnackBarType.error),
      (msg) => JadalSnackBar.show(widget.rootContext, msg, type: SnackBarType.success),
    );
  }
}

/// Picker dialog for the team-registration variant (V12 §1): eligible teams are
/// tappable; ineligible ones are shown disabled with their reason.
class _TeamPickerDialog extends StatelessWidget {
  final RegisterableTeams data;
  const _TeamPickerDialog({required this.data});

  static String _reasonLabel(String? reason) => switch (reason) {
        'already_registered' => 'Already registered',
        'too_few_members' => 'Needs 3+ members',
        'registration_closed' => 'Registration closed',
        _ => 'Not eligible',
      };

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Dialog(
      backgroundColor: DebateTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.groups_rounded, color: JadalColors.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.registerAsTeam,
                      style: AppTextStyles.title(context)
                          .copyWith(color: DebateTheme.textPrimary(context)),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close_rounded,
                        color: DebateTheme.textSecondary(context), size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
                itemCount: data.teams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final t = data.teams[i];
                  return _TeamTile(
                    team: t,
                    onTap: t.eligible ? () => Navigator.of(context).pop(t.id) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  final RegisterableTeam team;
  final VoidCallback? onTap;
  const _TeamTile({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final eligible = team.eligible;
    final primary = DebateTheme.textPrimary(context);
    final muted = DebateTheme.textSecondary(context);
    return Material(
      color: DebateTheme.surfaceElevated(context).withValues(alpha: eligible ? 1 : 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: JadalColors.primaryBlue.withValues(alpha: eligible ? 0.12 : 0.06),
                ),
                child: Icon(Icons.groups_rounded,
                    size: 20, color: eligible ? JadalColors.primaryBlue : muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle(context)
                          .copyWith(color: eligible ? primary : muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${team.membersCount} members',
                      style: AppTextStyles.caption(context).copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (eligible)
                Icon(Icons.chevron_right_rounded, color: muted)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _TeamPickerDialog._reasonLabel(team.ineligibleReason),
                    style: AppTextStyles.small(context)
                        .copyWith(fontWeight: FontWeight.w700, color: muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
