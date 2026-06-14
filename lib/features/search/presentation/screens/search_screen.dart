import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/features/search/data/repositories/search_repository_impl.dart';
import 'package:jadal_app/features/search/domain/repositories/search_repository.dart';
import 'package:jadal_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:jadal_app/features/search/presentation/widgets/search_user_card.dart';
import 'package:jadal_app/features/search/presentation/widgets/search_team_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late SearchCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final SearchRepository repository = SearchRepositoryImpl();
    _cubit = SearchCubit(repository);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'ابحث عن مستخدمين أو فرق...',
            hintStyle: TextStyle(
              fontFamily: 'Cairo',
              color: JadalColors.primaryBlue,
            ),
            border: InputBorder.none,
          ),
          style: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontSize: context.fontSize(16),
          ),
          textDirection: TextDirection.rtl,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _cubit.search(value);
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<SearchCubit, SearchState>(
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
                'ابحث عن مستخدمين أو فرق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: JadalColors.judgesGrey,
                  fontSize: context.fontSize(16),
                ),
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
                  'لا توجد نتائج',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: JadalColors.judgesGrey,
                    fontSize: context.fontSize(16),
                  ),
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
                        'المستخدمون',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: context.fontSize(18),
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
                        'الفرق',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: context.fontSize(18),
                          fontWeight: FontWeight.bold,
                          color: JadalColors.primaryBlue,
                        ),
                      ),
                    ),
                    ...teams.map((t) => SearchTeamCard(team: t)),
                  ],
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