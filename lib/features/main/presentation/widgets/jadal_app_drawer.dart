import 'package:flutter/material.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/localization/widgets/locale_toggle_button.dart';
import 'package:jadal_app/core/services/contact_info.dart';
import 'package:jadal_app/core/services/external_links.dart';
import 'package:jadal_app/core/services/session_identity.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/theme/widgets/theme_toggle_button.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/core/widgets/jadal_surface.dart';
import 'package:jadal_app/features/complaints/presentation/screens/my_complaints_screen.dart';
import 'package:jadal_app/features/live_debate/presentation/pages/frameworks_list_screen.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/surveys_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/trainer_surveys_screen.dart';
import 'package:jadal_app/features/teams/presentation/screens/joinable_teams_screen.dart';
import 'package:jadal_app/features/teams/presentation/screens/teams_screen.dart';

/// The app's nav drawer — opens from the layout "start" edge automatically
/// based on locale/`Directionality`, so RTL/LTR both fall out for free.
/// This used to build from **three** independent async sources:
/// two live `GET /profile` calls (one for the header, one for the role gate)
/// plus the contact footer's own load. They resolved at different times, so the
/// drawer's items appeared in waves. Everything now comes from one future over
/// locally-cached values written at login, resolved once in [initState], so the
/// whole drawer paints in a single frame with no network call at all.
class JadalAppDrawer extends StatefulWidget {
  const JadalAppDrawer({super.key});

  @override
  State<JadalAppDrawer> createState() => _JadalAppDrawerState();
}

class _JadalAppDrawerState extends State<JadalAppDrawer> {
  late final Future<(SessionIdentity?, ContactInfo)> _session;

  @override
  void initState() {
    super.initState();
    // Created once — not in build — so a rebuild can't restart it and make
    // the drawer flash back to its empty state.
    _session = _load();
  }

  Future<(SessionIdentity?, ContactInfo)> _load() async {
    final results = await Future.wait([
      SessionIdentity.load(),
      ContactInfo.load(),
    ]);
    return (results[0] as SessionIdentity?, results[1] as ContactInfo);
  }

  void _go(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: FutureBuilder<(SessionIdentity?, ContactInfo)>(
          future: _session,
          builder: (context, snapshot) {
            // Nothing paints until everything is ready — a drawer that appears
            // whole is better than one that assembles itself in front of you.
            if (!snapshot.hasData) return const SizedBox.shrink();
            final (identity, contact) = snapshot.data!;
            return _DrawerBody(
              identity: identity,
              contact: contact,
              onNavigate: _go,
            );
          },
        ),
      ),
    );
  }
}

class _DrawerBody extends StatelessWidget {
  final SessionIdentity? identity;
  final ContactInfo contact;
  final void Function(Widget) onNavigate;

  const _DrawerBody({
    required this.identity,
    required this.contact,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final textColor = jadalTextPrimary(context);
    final role = identity?.role;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            loc.appName,
            style: AppTextStyles.headline(context).copyWith(color: textColor),
          ),
        ),
        if (identity != null) _IdentityRow(identity: identity!),
        // Appearance + language, as one settings block rather than two loose
        // icon buttons.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              LocaleToggleButton(),
              SizedBox(width: 8),
              ThemeToggleButton(),
            ],
          ),
        ),
        const Divider(height: 24),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _DrawerItem(
                icon: Icons.insights_rounded,
                label: loc.drawerAnalysis,
                onTap: () => onNavigate(const DebaterStatsScreen()),
              ),
              _DrawerItem(
                icon: Icons.workspaces_rounded,
                label: loc.drawerFrameworks,
                onTap: () => onNavigate(const FrameworksListScreen()),
              ),
              _DrawerItem(
                icon: Icons.assignment_rounded,
                label: loc.drawerSurveys,
                onTap: () => onNavigate(const SurveysScreen()),
              ),
              _DrawerItem(
                icon: Icons.report_gmailerrorred_rounded,
                label: loc.drawerMyComplaints,
                onTap: () => onNavigate(const MyComplaintsScreen()),
              ),
              if (role == 'trainer') ...[
                _DrawerItem(
                  icon: Icons.fact_check_rounded,
                  label: loc.drawerTrainerSurveys,
                  onTap: () => onNavigate(const TrainerSurveysScreen()),
                ),
                _DrawerItem(
                  icon: Icons.groups_rounded,
                  label: loc.drawerMyTeams,
                  onTap: () => onNavigate(const TeamsScreen()),
                ),
              ],
              if (role == 'debater')
                _DrawerItem(
                  icon: Icons.group_add_rounded,
                  label: loc.drawerJoinTeam,
                  onTap: () => onNavigate(const JoinableTeamsScreen()),
                ),
            ],
          ),
        ),
        if (!contact.isEmpty) _AboutUsCard(contact: contact),
      ],
    );
  }
}

/// Name, avatar and points — straight from the login cache.
class _IdentityRow extends StatelessWidget {
  final SessionIdentity identity;
  const _IdentityRow({required this.identity});

  @override
  Widget build(BuildContext context) {
    final avatar = identity.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: JadalColors.primaryBlue,
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? NetworkImage(avatar)
                : null,
            child: (avatar == null || avatar.isEmpty)
                ? Text(
                    identity.name.isEmpty
                        ? '?'
                        : identity.name.characters.first.toUpperCase(),
                    style: AppTextStyles.subtitle(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              identity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyEmphasis(
                context,
              ).copyWith(color: jadalTextPrimary(context)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: JadalColors.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: JadalColors.primaryOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${identity.points}',
                  style: AppTextStyles.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: JadalColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: AppTextStyles.body(context)),
      onTap: onTap,
    );
  }
}

/// The about-us block: a real card whose rows each open the right
/// external app instead of three lines of grey text.
class _AboutUsCard extends StatelessWidget {
  final ContactInfo contact;
  const _AboutUsCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    // `instagram` from the backend is a full URL, never a handle — the handle
    // comes from its own key, so no URL is ever built from the legacy field.
    final rows = <_ContactRow>[
      if (contact.phoneE164 != null)
        _ContactRow(
          icon: Icons.phone_rounded,
          label: loc.contactPhone,
          value: contact.phone ?? contact.phoneE164!,
          copyValue: contact.phoneE164!,
          color: JadalColors.positiveGreen,
          open: () => ExternalLinks.dial(contact.phoneE164!),
        ),
      if (contact.whatsapp != null)
        _ContactRow(
          icon: Icons.chat_rounded,
          label: loc.contactWhatsapp,
          value: contact.whatsapp!,
          copyValue: contact.whatsapp!,
          color: JadalColors.positiveGreen,
          open: () => ExternalLinks.whatsapp(contact.whatsapp!),
        ),
      if (contact.email != null)
        _ContactRow(
          icon: Icons.email_rounded,
          label: loc.contactEmail,
          value: contact.email!,
          copyValue: contact.email!,
          color: JadalColors.primaryBlue,
          open: () => ExternalLinks.email(contact.email!),
        ),
      if (contact.instagramUrl != null || contact.instagramHandle != null)
        _ContactRow(
          icon: Icons.camera_alt_rounded,
          label: loc.contactInstagram,
          value: contact.instagramHandle ?? contact.instagramUrl!,
          copyValue: contact.instagramUrl ?? contact.instagramHandle!,
          color: JadalColors.primaryOrange,
          open: () => ExternalLinks.instagram(
            handle: contact.instagramHandle,
            url: contact.instagramUrl,
          ),
        ),
      if (contact.website != null)
        _ContactRow(
          icon: Icons.language_rounded,
          label: loc.contactWebsite,
          value: contact.website!,
          copyValue: contact.website!,
          color: JadalColors.deepBlue,
          open: () => ExternalLinks.web(contact.website!),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: JadalSurface(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.drawerAboutUs,
              style: AppTextStyles.caption(context).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: jadalTextSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < rows.length; i++) ...[
              if (i != 0) const SizedBox(height: 4),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String copyValue;
  final Color color;
  final Future<bool> Function() open;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.copyValue,
    required this.color,
    required this.open,
  });

  Future<void> _onTap(BuildContext context) async {
    final copied = context.loc.copiedToClipboard;
    if (await open()) return;
    // Nothing could handle it (no dialler, Instagram not installed and no
    // browser, …) — copying beats a tap that silently does nothing.
    await ExternalLinks.copy(copyValue);
    if (!context.mounted) return;
    JadalSnackBar.show(context, copied, type: SnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: jadalIsDark(context) ? 0.20 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.small(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: jadalTextSecondary(context),
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: jadalTextPrimary(context)),
                    ),
                  ],
                ),
              ),
              Icon(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 18,
                color: jadalTextSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
