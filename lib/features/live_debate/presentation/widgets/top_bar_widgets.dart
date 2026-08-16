import 'package:flutter/material.dart';

import '../../../../core/app_models/motion.dart';
import '../../../../core/constants/appImgaeAsset.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/jadal_dialog.dart';
import '../cubits/debate_controller.dart';
import '../utils/avatar_palette.dart';
import '../utils/debate_theme.dart';

/// Compact (small-width) button opening the viewers dialog.
class AudienceButton extends StatelessWidget {
  final DebateController cubit;
  const AudienceButton({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return _TopBarIconButton(
      icon: Icons.groups_2_rounded,
      onTap: () => showDialog(
        context: context,
        builder: (_) => AudienceDialog(cubit: cubit),
      ),
    );
  }
}

/// One row in the viewers dialog (a judge, an audience member, or the local user).
class _Viewer {
  final String id;
  final String name;
  final String role;
  final bool isMe;
  const _Viewer({required this.id, required this.name, required this.role, this.isMe = false});
}

/// Motion button using the existing motion image. Falls back to
/// an icon if the asset isn't bundled yet.
class MotionButton extends StatelessWidget {
  final Motion motion;
  const MotionButton({super.key, required this.motion});

  @override
  Widget build(BuildContext context) {
    final tint = DebateTheme.textPrimary(context);
    return _TopBarIconButton(
      onTap: () => showDialog(
        context: context,
        builder: (_) => MotionDialog(motion: motion),
      ),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        child: Image.asset(
          AppImageAsset.motionImage,
          height: 24,
          errorBuilder: (_, _, _) => Icon(Icons.campaign_rounded, color: tint),
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  const _TopBarIconButton({this.icon, this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebateTheme.surfaceElevated(context),
      borderRadius: BorderRadius.circular(widgetBorderRadius - 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(widgetBorderRadius - 6),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widgetBorderRadius - 6),
            border: Border.all(
              color: JadalColors.primaryBlue.withValues(alpha: 0.18),
            ),
          ),
          child: child ?? Icon(icon, color: DebateTheme.textPrimary(context)),
        ),
      ),
    );
  }
}

/// Large, searchable list of who's watching: judges + audience + (always) the
/// local user — unless they're a debater in the match.
class AudienceDialog extends StatefulWidget {
  final DebateController cubit;
  const AudienceDialog({super.key, required this.cubit});

  @override
  State<AudienceDialog> createState() => _AudienceDialogState();
}

class _AudienceDialogState extends State<AudienceDialog> {
  String _query = '';

  List<_Viewer> _buildViewers(BuildContext context) {
    final loc = context.loc;
    final cubit = widget.cubit;
    final me = cubit.data.currentUserId;
    final isDebater = cubit.data.propositionTeam.debaterById(me) != null ||
        cubit.data.oppositionTeam.debaterById(me) != null;
    final seen = <String>{};
    final out = <_Viewer>[];
    // Only the judges ACTUALLY in the room (real presence), not the whole
    // judge roster pinned. Mock reports everyone present → the demo is unchanged.
    for (final j in cubit.data.judges) {
      if (!cubit.isUserPresent(j.id)) continue;
      if (seen.add(j.id)) {
        out.add(_Viewer(id: j.id, name: j.name, role: loc.judgeRole, isMe: j.id == me));
      }
    }
    for (final a in cubit.data.audience) {
      if (seen.add(a.id)) {
        out.add(_Viewer(id: a.id, name: a.name, role: a.role, isMe: a.id == me));
      }
    }
    // I should always see myself here unless I'm a debater in the match.
    if (!isDebater && !seen.contains(me)) {
      final myName = cubit.localParticipant?.name ?? '';
      out.add(_Viewer(
        id: me,
        name: myName.isNotEmpty ? myName : loc.youTag,
        role: loc.youTag,
        isMe: true,
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    final all = _buildViewers(context);
    final filtered =
        all.where((m) => m.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return JadalDialog(
      width: size.width * 0.9,
      height: size.height * 0.7,
      firstColor: JadalColors.primaryBlue,
      secondColor: JadalColors.primaryOrange,
      bodyColor: DebateTheme.surface(context),
      icon: Icons.groups_2_rounded,
      title: '${loc.audience} (${all.length})',
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.body(context).copyWith(color: DebateTheme.textPrimary(context)),
              decoration: InputDecoration(
                hintText: loc.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(loc.noMatches,
                          style: AppTextStyles.body(context).copyWith(color: DebateTheme.textSecondary(context))),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        // The local user's row is gently highlighted so you can
                        // always spot yourself.
                        final accent =
                            m.isMe ? JadalColors.primaryBlue : Colors.transparent;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: DebateTheme.surfaceElevated(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: accent.withValues(alpha: m.isMe ? 0.5 : 0.0)),
                          ),
                          child: Row(
                            children: [
                              // Neutral initial avatar (no rainbow colours) — a
                              // soft brand-blue chip keeps the list calm.
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: JadalColors.primaryBlue.withValues(
                                    alpha: DebateTheme.isDark(context) ? 0.18 : 0.10,
                                  ),
                                ),
                                child: Text(
                                  avatarInitial(m.name),
                                  style: AppTextStyles.body(context).copyWith(
                                    color: JadalColors.primaryBlue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m.isMe ? '${m.name} • ${loc.youTag}' : m.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: DebateTheme.textPrimary(context),
                                  ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: JadalColors.primaryBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  m.role,
                                  style: AppTextStyles.small(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: JadalColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

/// The motion, presented as a centred "quote": a big quote glyph over the motion
/// text, with its frameworks/tags shown only as calm neutral pills underneath
/// (their brand colours are intentionally dropped — design over branding).
class MotionDialog extends StatelessWidget {
  final Motion motion;
  const MotionDialog({super.key, required this.motion});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    final hasMeta = motion.frameworks.isNotEmpty || motion.tags.isNotEmpty;

    return JadalDialog(
      width: size.width * 0.86,
      height: size.height * 0.46,
      firstColor: JadalColors.primaryBlue,
      secondColor: JadalColors.primaryOrange,
      bodyColor: DebateTheme.surface(context),
      icon: Icons.campaign_rounded,
      title: loc.motion,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 46,
                        color: JadalColors.primaryOrange.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        motion.text,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline(context).copyWith(
                          height: 1.5,
                          color: DebateTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasMeta) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final f in motion.frameworks) _MetaPill(label: f.name, filled: true),
                  for (final t in motion.tags) _MetaPill(label: t, filled: false),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small, neutral pill for a framework (soft fill) or tag (outline) — no brand
/// colour, so the motion stays the focus.
class _MetaPill extends StatelessWidget {
  final String label;
  final bool filled;
  const _MetaPill({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    final dark = DebateTheme.isDark(context);
    final muted = DebateTheme.textSecondary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled
            ? (dark ? Colors.white.withValues(alpha: 0.07) : muted.withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: muted.withValues(alpha: filled ? 0.0 : 0.30)),
      ),
      child: Text(
        label,
        style: AppTextStyles.small(context).copyWith(fontWeight: FontWeight.w700, color: muted),
      ),
    );
  }
}
