import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/localization/widgets/locale_toggle_button.dart';
import 'package:jadal_app/core/services/contact_info.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/widgets/theme_toggle_button.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/complaints/presentation/screens/my_complaints_screen.dart';
import 'package:jadal_app/features/live_debate/presentation/pages/frameworks_list_screen.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/domain/entities/profile.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/surveys_screen.dart';
import 'package:jadal_app/features/surveys/presentation/screens/trainer_surveys_screen.dart';
import 'package:jadal_app/features/teams/presentation/screens/joinable_teams_screen.dart';
import 'package:jadal_app/features/teams/presentation/screens/teams_screen.dart';

/// The app's nav drawer (§9) — opens from the layout "start" edge automatically
/// based on locale/`Directionality`, so RTL/LTR both fall out for free. Holds
/// what used to live in the (now removed) Profile app-bar actions plus the
/// two new entries and a contact-info footer sourced from login (§9 backend).
class JadalAppDrawer extends StatelessWidget {
  const JadalAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Jadal',
                  style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
            ),
            // V2 §3 — the signed-in user + their points, right at the top of
            // the drawer. Same lazy FutureBuilder pattern as the contact
            // footer below; renders nothing until (or unless) it resolves.
            FutureBuilder<Either<Failure, Profile>>(
              future: di.sl<ProfileRepository>().getProfile(),
              builder: (context, snapshot) {
                final profile = snapshot.data?.toNullable();
                if (profile == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: JadalColors.primaryBlue,
                        backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                            ? Text(
                                profile.name.isEmpty
                                    ? '?'
                                    : profile.name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textColor),
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
                            const Icon(Icons.star_rounded,
                                size: 14, color: JadalColors.primaryOrange),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.points}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12.5,
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
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  LocaleToggleButton(),
                  SizedBox(width: 8),
                  ThemeToggleButton(),
                ],
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.insights_rounded),
              title: const Text('Your analysis', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebaterStatsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('Frameworks in the system', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FrameworksListScreen()),
                );
              },
            ),
              ListTile(
              leading: const Icon(Icons.assignment_rounded),
              title: const Text('Surveys', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SurveysScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_rounded),
              title: const Text('My Complaints', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyComplaintsScreen()),
                );
              },
            ),
            FutureBuilder<Either<Failure, Profile>>(
              future: di.sl<ProfileRepository>().getProfile(),
              builder: (context, snapshot) {
                final profile = snapshot.data?.toNullable();
                if (profile == null) return const SizedBox.shrink();
                if (profile.role == 'trainer') {
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.assignment_rounded),
                        title: const Text('Trainer Surveys', style: TextStyle(fontFamily: 'Cairo')),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TrainerSurveysScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.groups_rounded),
                        title: const Text('My Teams', style: TextStyle(fontFamily: 'Cairo')),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TeamsScreen()),
                          );
                        },
                      ),
                    ],
                  );
                }
                if (profile.role == 'debater') {
                  return ListTile(
                    leading: const Icon(Icons.group_add_rounded),
                    title: const Text('Join a Team', style: TextStyle(fontFamily: 'Cairo')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JoinableTeamsScreen()),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<ContactInfo>(
                future: ContactInfo.load(),
                builder: (context, snapshot) {
                  final contact = snapshot.data;
                  if (contact == null || contact.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact us',
                          style: TextStyle(
                              fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12, color: textColor)),
                      const SizedBox(height: 6),
                      if (contact.email != null) _ContactRow(icon: Icons.email_outlined, text: contact.email!),
                      if (contact.phone != null) _ContactRow(icon: Icons.phone_outlined, text: contact.phone!),
                      if (contact.instagram != null)
                        _ContactRow(icon: Icons.camera_alt_outlined, text: contact.instagram!),
                    ],
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

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: JadalColors.judgesGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: JadalColors.judgesGrey)),
          ),
        ],
      ),
    );
  }
}
