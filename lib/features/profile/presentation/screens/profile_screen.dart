import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/widgets/locale_toggle_button.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/widgets/theme_toggle_button.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/auth/presentation/screens/login_screen.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:jadal_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:jadal_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_info_card.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_action_button.dart';
import 'package:jadal_app/features/statistics/presentation/pages/debater_stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileCubit _cubit;

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cubit.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final repository = ProfileRepository();
    _cubit = ProfileCubit(repository);
    _cubit.loadProfile();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Until a dedicated settings screen exists, the theme/language toggles
      // live here (moved out of the main shell's — now removed — app bar).
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [
          LocaleToggleButton(),
          SizedBox(width: 6),
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is ProfileLogoutSuccess) {
            JadalSnackBar.show(context, state.message, type: SnackBarType.success);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }

          if (state is ProfileError) {
            JadalSnackBar.show(context, state.message, type: SnackBarType.error);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            final profile = state.profile;
            return RefreshIndicator(
              onRefresh: () => _cubit.loadProfile(),
              color: JadalColors.primaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(context.wp(5)),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        name: profile.name,
                        avatarUrl: profile.avatarUrl,
                      ),
                      SizedBox(height: context.hp(1)),
                      Text(
                        profile.name,
                        style: TextStyle(
                          fontSize: context.fontSize(24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profile.email,
                        style: TextStyle(
                          fontSize: context.fontSize(16),
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: context.hp(1)),
                      Row(
                        children: [
                          Expanded(
                            child: ProfileActionButton(
                              text: 'Edit Profile',
                              icon: Icons.edit,
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      currentName: profile.name,
                                      currentPhone: profile.phone ?? '',
                                      currentAvatarUrl: profile.avatarUrl,
                                    ),
                                  ),
                                );
                                if (result != null) _cubit.loadProfile();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ProfileActionButton(
                              text: 'Change Password',
                              icon: Icons.lock,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePasswordScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.hp(2)),
                      // Entry point to the debater statistics screens (moved
                      // here from the debates-list app bar).
                      ProfileActionButton(
                        text: 'Statistics',
                        icon: Icons.insights_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DebaterStatsScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: context.hp(1)),
                      ProfileInfoCard(
                        icon: Icons.badge,
                        label: 'Role',
                        value: profile.role,
                      ),
                      ProfileInfoCard(
                        icon: Icons.star,
                        label: 'Points',
                        value: '${profile.points}',
                      ),
                      ProfileInfoCard(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: profile.phone ?? 'Not provided',
                      ),
                      ProfileInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Joined',
                        value: profile.createdAt.split('T')[0],
                      ),
                      SizedBox(height: context.hp(1)),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: ProfileActionButton(
                            text: 'Logout',
                            icon: Icons.logout,
                            textColor: Colors.red,
                            borderColor: Colors.red,
                            onPressed: () {
                              _showLogoutConfirmation();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cubit.loadProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}