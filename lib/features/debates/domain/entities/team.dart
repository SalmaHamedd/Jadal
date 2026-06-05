import 'package:equatable/equatable.dart';

import '../../../../core/constants/debate_constants.dart';
import 'debater.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final TeamSide side;
  final List<Debater> debaters;

  Team({
    required this.id,
    required this.name,
    required this.side,
    required this.debaters,
  });

  Team copyWith({
    String? id,
    String? name,
    TeamSide? side,
    List<Debater>? debaters,
  }) =>
      Team(
        id: id ?? this.id,
        name: name ?? this.name,
        side: side ?? this.side,
        debaters: debaters ?? this.debaters,
      );

  @override
  List<Object?> get props => [id, name, side, debaters];
}
