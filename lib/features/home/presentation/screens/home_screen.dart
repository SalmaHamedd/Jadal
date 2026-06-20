import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/presentation/cubit/blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/home_blog_section.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/profile/presentation/cubit/profile_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BlogCubit>(
          create: (_) {
            final BlogRepository repository = BlogRepositoryImpl();
            return BlogCubit(repository)..loadBlogs();
          },
        ),
        BlocProvider<ProfileCubit>(
          create: (_) {
            final ProfileRepository repository = ProfileRepository();
            return ProfileCubit(repository)..loadProfile();
          },
        ),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  if (state is ProfileLoaded) {
                    return Text(
                      'مرحباً بك، ${state.profile.name} 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else if (state is ProfileLoading) {
                    return const Text(
                      'جاري التحميل...',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    );
                  } else if (state is ProfileError) {
                    return const Text(
                      'مرحباً بك 👋',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    );
                  }
                  return const Text(
                    'مرحباً بك 👋',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text('اكتشف أحدث المقالات والمناظرات'),
              const SizedBox(height: 16),
              const HomeBlogSection(),
            ],
          ),
        ),
      ),
    );
  }
}