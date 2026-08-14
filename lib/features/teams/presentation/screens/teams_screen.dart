import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_error_view.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/features/live_debate/presentation/widgets/debate_screen_header.dart';
import 'package:jadal_app/features/teams/data/repositories/team_repository_impl.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';
import 'package:jadal_app/features/teams/presentation/cubit/team_cubit.dart';
import 'package:jadal_app/features/teams/presentation/screens/create_team_screen.dart';
import 'package:jadal_app/features/teams/presentation/screens/team_detail_screen.dart';
import 'package:jadal_app/features/teams/presentation/widgets/team_list_card.dart';
import 'package:jadal_app/core/error/failure_text.dart';

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
              // MF_FU §10.3 — the shared in-body header, matching statistics
              // and the debate detail, rather than a thin AppBar title.
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: SafeArea(
                  bottom: false,
                  child: DebateScreenHeader(title: context.loc.drawerMyTeams),
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: JadalColors.primaryOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(
                  context.loc.teamNewTeamTitle,
                  style: AppTextStyles.button(
                    context,
                  ).copyWith(color: Colors.white),
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
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.18,
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: JadalColors.judgesGrey.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  size: 56,
                                  color: JadalColors.judgesGrey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                context.loc.teamNoneYet,
                                style: AppTextStyles.subtitle(context),
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
                    return JadalErrorScrollView(
                      message: FailureText.fromMessage(context, state.message),
                      onRetry: () => context.read<TeamCubit>().loadTeams(),
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
