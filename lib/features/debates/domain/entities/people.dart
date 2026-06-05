import 'package:equatable/equatable.dart';

class Judge extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;

  const Judge({required this.id, required this.name, this.avatarUrl});

  @override
  List<Object?> get props => [id, name, avatarUrl];
}

class Coach extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;

  const Coach({required this.id, required this.name, this.avatarUrl});

  @override
  List<Object?> get props => [id, name, avatarUrl];
}
