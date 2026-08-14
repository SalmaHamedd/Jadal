import 'package:flutter/material.dart';

import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/debate_list_model.dart';
import '../../domain/debate_status.dart';
import '../utils/debate_date.dart';
import '../utils/debate_theme.dart';

/// The app's ONE debate card.
///
/// Every card floats the same way — one soft neutral elevation, no per-stage
/// colour. The single blue→orange accent stripe is the only brand colour and it
/// is identical on every card, so a list reads calm rather than as a stack of
/// coloured blocks.
///
/// MF_FU §2.4 — this used to be private to the debates screen, while the
/// profile's "latest debates" (and its "show all" page) had their own
/// `DebateRowCard` that tinted the whole row orange for completed and red for
/// cancelled. Five of those stacked was repetitive and loud. Both surfaces now
/// share this widget; status is carried by [showStatusPill] as *text*, never by
/// the card's colour.
class DebateListCard extends StatelessWidget {
  final DebateListItem item;
  final VoidCallback onTap;

  /// Adds a text-led status pill. Used by the profile lists, where a debate's
  /// outcome matters; the debates screen groups by stage already, so it leaves
  /// this off.
  final bool showStatusPill;

  /// Renders for a narrow column (the profile's card sits inside another card,
  /// so it has far less width than the debates screen). Tightens the type
  /// scale and drops the motion line, which stacks badly at that width.
  final bool compact;

  const DebateListCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showStatusPill = false,
    this.compact = false,
  });

  ({String label, Color color})? _status(BuildContext context) {
    if (!showStatusPill) return null;
    return switch (item.status) {
      DebateStatus.completed => (
        label: context.loc.tabDone,
        color: JadalColors.judgesGrey,
      ),
      DebateStatus.cancelled => (
        label: context.loc.tabCancelled,
        color: JadalColors.negativeRed,
      ),
      DebateStatus.live => (
        label: context.loc.tabLive,
        color: JadalColors.primaryOrange,
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dark = DebateTheme.isDark(context);
    final radius = BorderRadius.circular(compact ? 16 : 20);
    final status = _status(context);

    // In compact mode this card is nested INSIDE a JadalSurface, which paints
    // the very same `darkSurfaceElevated` / `lightSurface` tone — so the card
    // vanished into its container. Shift it away from the parent instead of
    // reusing the standard elevated colour.
    final surface = compact
        ? (dark
              ? Color.lerp(JadalColors.darkSurfaceElevated, Colors.white, 0.07)!
              : Color.lerp(
                  JadalColors.lightSurface,
                  JadalColors.primaryBlue,
                  0.05,
                )!)
        : DebateTheme.surfaceElevated(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.36 : 0.08),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            // A hairline keeps the elevated surface from melting into the dark
            // blue background.
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : JadalColors.primaryBlue.withValues(alpha: 0.06),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          JadalColors.primaryBlue,
                          JadalColors.primaryOrange,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // The status pill moved OUT of the meta row: sharing
                          // one line with the format and the date pushed the
                          // date off-screen in the profile's narrow column, so
                          // it was effectively never visible.
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      (compact
                                              ? AppTextStyles.subtitle(context)
                                              : AppTextStyles.title(context))
                                          .copyWith(
                                            height: 1.3,
                                            color: DebateTheme.textPrimary(
                                              context,
                                            ),
                                          ),
                                ),
                              ),
                              if (status != null) ...[
                                const SizedBox(width: 8),
                                _Pill(label: status.label, color: status.color),
                              ],
                            ],
                          ),
                          // Registration cards show only title/format/date (§U2).
                          // The motion is dropped in compact mode — two more
                          // wrapped lines in a narrow column read as a wall.
                          if (!compact &&
                              item.status != DebateStatus.scheduled &&
                              item.motion?.text.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.motion!.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(context).copyWith(
                                height: 1.4,
                                color: DebateTheme.textSecondary(context),
                              ),
                            ),
                          ],
                          SizedBox(height: compact ? 8 : 12),
                          // Wrap, not Row: a long format name used to overflow
                          // rather than move to the next line.
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (item.tag != null && item.tag!.isNotEmpty)
                                _Pill(
                                  label: item.tag!,
                                  color: JadalColors.primaryOrange,
                                ),
                              if (item.format.name != null)
                                _Meta(
                                  icon: Icons.tune_rounded,
                                  label: item.format.name!,
                                ),
                              if (item.scheduledAt != null)
                                _Meta(
                                  icon: Icons.event_rounded,
                                  label: formatDebateDate(item.scheduledAt),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One icon + label meta item. Lives inside a [Wrap], so it must size to its
/// content and never assume a full row is available.
class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = DebateTheme.textSecondary(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        // Bounded so a very long format name ellipsises instead of overflowing
        // — the previous Row let it run past the card edge.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(context).copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.small(
          context,
        ).copyWith(fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
