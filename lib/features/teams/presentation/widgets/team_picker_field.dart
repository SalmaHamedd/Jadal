import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/teams/data/repositories/team_repository_impl.dart';
import 'package:jadal_app/features/teams/presentation/cubit/team_cubit.dart';

/// Lets the trainer pick which of their teams a survey should go to, backed
/// by `GET /teams`. Renders as a plain column (no internal scrolling) so it
/// sits naturally inside a surrounding scrollable form.
class TeamPickerField extends StatelessWidget {
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  const TeamPickerField({super.key, required this.selectedIds, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TeamCubit(TeamRepositoryImpl())..loadTeams(),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return BlocBuilder<TeamCubit, TeamState>(
            builder: (context, state) {
              if (state is TeamLoading || state is TeamInitial) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              } else if (state is TeamError) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.loc.teamLoadListFailed(state.message),
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.read<TeamCubit>().loadTeams(),
                        child: Text(context.loc.retry, style: const TextStyle(fontFamily: 'Cairo')),
                      ),
                    ],
                  ),
                );
              } else if (state is TeamLoaded) {
                if (state.teams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.loc.teamNoneAvailableForYou,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? JadalColors.darkSurfaceElevated : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: state.teams.map((team) {
                      final selected = selectedIds.contains(team.id);
                      return CheckboxListTile(
                        value: selected,
                        activeColor: JadalColors.primaryOrange,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        title: Text(
                          team.name,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? JadalColors.darkTextPrimary
                                : JadalColors.lightTextPrimary,
                          ),
                        ),
                        subtitle: Text(
                          [
                            context.loc.teamMembersCountShort(team.membersCount),
                            if (team.leaderName != null) context.loc.teamLeaderLabel(team.leaderName!),
                          ].join(' • '),
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 11.5),
                        ),
                        onChanged: (v) {
                          final next = {...selectedIds};
                          if (v ?? false) {
                            next.add(team.id);
                          } else {
                            next.remove(team.id);
                          }
                          onChanged(next);
                        },
                      );
                    }).toList(),
                  ),
                );
              }
              return const SizedBox();
            },
          );
        },
      ),
    );
  }
}
