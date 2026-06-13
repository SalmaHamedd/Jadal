part of 'search_cubit.dart';

abstract class SearchState extends Equatable {
  const SearchState();
}

class SearchInitial extends SearchState {
  @override List<Object> get props => [];
}

class SearchLoading extends SearchState {
  @override List<Object> get props => [];
}

class SearchLoaded extends SearchState {
  final List<SearchUser> users;
  final List<SearchTeam> teams;

  const SearchLoaded({required this.users, required this.teams});

  @override List<Object> get props => [users, teams];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override List<Object> get props => [message];
}