import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/colors.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:jadal_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:jadal_app/features/profile/presentation/widgets/profile_info_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileCubit _cubit;

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
      body: BlocBuilder<ProfileCubit, ProfileState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileLoaded) {
            final profile = state.profile;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(context.wp(5)),
                child: Column(
                  children: [
                    SizedBox(height: context.hp(6)),
                    ProfileAvatar(
                      name: profile.name,
                    ),
                    SizedBox(height: context.hp(2)),
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
                    SizedBox(height: context.hp(2)),
                    OutlinedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              currentName: profile.name,
                              currentPhone: profile.phone ?? '',
                            ),
                          ),
                        );
                        if (result != null) {
                          _cubit.loadProfile();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryblue,
                        side: BorderSide(color: AppColors.primaryblue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                    SizedBox(height: context.hp(3)),
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
                  ],
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
