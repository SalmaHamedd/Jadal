import 'package:equatable/equatable.dart';

enum TeamSide { government, opposition }

extension TeamSideArabic on TeamSide {
  String get arabicLabel => switch (this) {
        TeamSide.government => 'الحكومة',
        TeamSide.opposition => 'المعارضة',
      };
}

class Debater extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final int priority;

  const Debater({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.priority = 0,
  });

  Debater copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
    int? priority,
  }) =>
      Debater(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isOnline: isOnline ?? this.isOnline,
        priority: priority ?? this.priority,
      );

  @override
  List<Object?> get props => [id, name, avatarUrl, isOnline, priority];
}
