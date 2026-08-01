import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/features/profile/data/repositories/profile_repository.dart';
import 'package:jadal_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:jadal_app/features/search/domain/repositories/search_repository.dart';
import 'package:jadal_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:jadal_app/features/search/presentation/widgets/search_user_card.dart';
import 'package:jadal_app/features/search/presentation/widgets/search_team_card.dart';
import 'package:jadal_app/features/main/presentation/screens/main_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late SearchCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isDebater = false;

  @override
  void initState() {
    super.initState();
    final SearchRepository repository = SearchRepositoryImpl();
    _cubit = SearchCubit(repository);
    // Only debaters can request to join a team from here — the join button
    // on each SearchTeamCard is gated on this.
    ProfileRepository().getProfile().then((result) {
      if (!mounted) return;
      result.fold((_) {}, (profile) {
        if (profile.role == 'debater') setState(() => _isDebater = true);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.deepBlue;
    final fieldFill = isDark
        ? JadalColors.darkSurfaceElevated
        : JadalColors.lightSurface;
    final fieldText = isDark
        ? JadalColors.darkTextPrimary
        : JadalColors.lightTextPrimary;
    final fieldHint = isDark
        ? JadalColors.darkTextSecondary
        : JadalColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          context.loc.searchTitle,
          style: AppTextStyles.displayTitle(
            context,
          ).copyWith(color: titleColor),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: fieldFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: JadalColors.primaryBlue.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: context.loc.searchUsersTeamsHint,
                  hintStyle: AppTextStyles.body(
                    context,
                  ).copyWith(color: fieldHint),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: JadalColors.primaryOrange,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: AppTextStyles.subtitle(
                  context,
                ).copyWith(color: fieldText),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _cubit.search(value);
                  }
                },
              ),
            ),
          ),
          Expanded(child: _buildResults(context)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return BlocConsumer<SearchCubit, SearchState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state is SearchError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: JadalColors.primaryOrange,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SearchInitial) {
          return Center(
            child: Text(
              context.loc.searchUsersTeamsPrompt,
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: JadalColors.judgesGrey),
            ),
          );
        } else if (state is SearchLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SearchLoaded) {
          final users = state.users;
          final teams = state.teams;

          if (users.isEmpty && teams.isEmpty) {
            return Center(
              child: Text(
                context.loc.noResults,
                style: AppTextStyles.subtitle(
                  context,
                ).copyWith(color: JadalColors.judgesGrey),
              ),
            );
          }

          return RefreshIndicator(
            color: JadalColors.primaryOrange,
            onRefresh: () async {
              if (_searchController.text.trim().isNotEmpty) {
                _cubit.search(_searchController.text.trim());
              }
            },
            child: ListView(
              padding: EdgeInsets.all(context.wp(4)),
              children: [
                if (users.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: context.hp(2)),
                    child: Text(
                      context.loc.usersSection,
                      style: AppTextStyles.headline(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: JadalColors.primaryBlue,
                      ),
                    ),
                  ),
                  ...users.map((u) => SearchUserCard(user: u)),
                  SizedBox(height: context.hp(2)),
                ],
                if (teams.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: context.hp(2)),
                    child: Text(
                      context.loc.teamsSection,
                      style: AppTextStyles.headline(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: JadalColors.primaryBlue,
                      ),
                    ),
                  ),
                  ...teams.map(
                    (t) => SearchTeamCard(team: t, canJoin: _isDebater),
                  ),
                ],
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
