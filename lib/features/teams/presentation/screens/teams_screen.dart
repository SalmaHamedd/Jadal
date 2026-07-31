import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/teams/data/repositories/team_repository_impl.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';
import 'package:jadal_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:jadal_app/features/teams/presentation/screens/create_team_screen.dart';
import 'package:jadal_app/features/teams/presentation/screens/team_detail_screen.dart';
import 'package:jadal_app/features/teams/presentation/widgets/team_list_card.dart';

/// The trainer's "My Teams" screen — list, create, and drill into a team to
/// manage its roster. Mirrors the trainer surveys screen's structure.
class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TeamRepository repository = TeamRepositoryImpl();

    return BlocProvider(
      create: (_) => TeamCubit(repository)..loadTeams(),
      child: Builder(
        builder: (context) {
          return JadalGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  context.loc.drawerMyTeams,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: JadalColors.primaryOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(
                  context.loc.teamNewTeamTitle,
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateTeamScreen(repository: repository),
                    ),
                  );
                  if (created == true && context.mounted) {
                    context.read<TeamCubit>().loadTeams();
                  }
                },
              ),
              body: BlocBuilder<TeamCubit, TeamState>(
                builder: (context, state) {
                  if (state is TeamLoading || state is TeamInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TeamLoaded) {
                    final teams = state.teams;
                    if (teams.isEmpty) {
                      return RefreshIndicator(
                        color: JadalColors.primaryOrange,
                        onRefresh: () => context.read<TeamCubit>().loadTeams(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                context.loc.teamNoneYet,
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: JadalColors.primaryOrange,
                      onRefresh: () => context.read<TeamCubit>().loadTeams(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          return TeamListCard(
                            team: team,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeamDetailScreen(
                                    team: team,
                                    repository: repository,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                context.read<TeamCubit>().loadTeams();
                              }
                            },
                          );
                        },
                      ),
                    );
                  } else if (state is TeamError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: JadalColors.judgesGrey),
                          const SizedBox(height: 16),
                          Text(
                            context.loc.errorWithMessage(state.message),
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.read<TeamCubit>().loadTeams(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: JadalColors.primaryOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(context.loc.retry),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
