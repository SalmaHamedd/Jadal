import 'package:jadal_app/features/search/data/models/search_user_model.dart';
import 'package:jadal_app/features/search/data/models/search_team_model.dart';

class SearchResponseModel {
  final List<SearchUserModel> users;
  final List<SearchTeamModel> teams;

  SearchResponseModel({required this.users, required this.teams});

  factory SearchResponseModel.fromJson(Map<String, dynamic> json) {
    final usersData = json['data']['users']['items'] as List;
    final teamsData = json['data']['teams']['items'] as List;

    return SearchResponseModel(
      users: usersData.map((u) => SearchUserModel.fromJson(u)).toList(),
      teams: teamsData.map((t) => SearchTeamModel.fromJson(t)).toList(),
    );
  }
}