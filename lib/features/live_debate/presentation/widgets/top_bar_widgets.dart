import 'package:flutter/material.dart';

import '../../../../core/constants/appImgaeAsset.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/localization/l10n/context_localiztion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jadal_dialog.dart';
import '../../data/models/debate_models.dart';
import '../utils/avatar_palette.dart';
import '../utils/debate_theme.dart';

/// Compact (small-width) button opening the audience dialog (§8.3 A, left).
class AudienceButton extends StatelessWidget {
  final List<AudienceMember> audience;
  const AudienceButton({super.key, required this.audience});

  @override
  Widget build(BuildContext context) {
    return _TopBarIconButton(
      icon: Icons.groups_2_rounded,
      onTap: () => showDialog(
        context: context,
        builder: (_) => AudienceDialog(audience: audience),
      ),
    );
  }
}

/// Motion button using the existing motion image (§8.3 A, right). Falls back to
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

/// Large, searchable list of the debate audience + their roles (§8.3 A).
class AudienceDialog extends StatefulWidget {
  final List<AudienceMember> audience;
  const AudienceDialog({super.key, required this.audience});

  @override
  State<AudienceDialog> createState() => _AudienceDialogState();
}

class _AudienceDialogState extends State<AudienceDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    final filtered = widget.audience
        .where((m) => m.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return JadalDialog(
      width: size.width * 0.9,
      height: size.height * 0.7,
      firstColor: JadalColors.primaryBlue,
      secondColor: JadalColors.primaryOrange,
      bodyColor: DebateTheme.surface(context),
      title: '${loc.audience} (${widget.audience.length})',
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontFamily: 'Cairo', color: DebateTheme.textPrimary(context)),
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
                          style: TextStyle(
                              fontFamily: 'Cairo', color: DebateTheme.textSecondary(context))),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: DebateTheme.surfaceElevated(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: avatarColorFor(m.id),
                                child: Text(
                                  avatarInitial(m.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
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
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
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

/// Small dialog: motion title + the categories it belongs to + tags (if any).
class MotionDialog extends StatelessWidget {
  final Motion motion;
  const MotionDialog({super.key, required this.motion});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final size = MediaQuery.of(context).size;
    return JadalDialog(
      width: size.width * 0.86,
      height: size.height * 0.5,
      firstColor: JadalColors.primaryBlue,
      secondColor: JadalColors.primaryOrange,
      bodyColor: DebateTheme.surface(context),
      title: loc.motion,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (motion.categories.isNotEmpty) ...[
              _ChipsRow(label: loc.categories, items: motion.categories, color: JadalColors.primaryBlue),
              const SizedBox(height: 10),
            ],
            if (motion.tags.isNotEmpty) ...[
              _ChipsRow(label: loc.tags, items: motion.tags, color: JadalColors.primaryOrange),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DebateTheme.surfaceElevated(context),
                  borderRadius: BorderRadius.circular(widgetBorderRadius),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    motion.title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.4,
                      color: DebateTheme.textPrimary(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;
  const _ChipsRow({required this.label, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$label:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
