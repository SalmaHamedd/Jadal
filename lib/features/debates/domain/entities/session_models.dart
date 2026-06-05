import 'package:equatable/equatable.dart';

import 'debater.dart';

enum SessionPhase { opening, rebuttal, closing }

extension SessionPhaseArabic on SessionPhase {
  String get arabicLabel => switch (this) {
        SessionPhase.opening => 'الافتتاح',
        SessionPhase.rebuttal => 'الرد',
        SessionPhase.closing => 'الختام',
      };
}

enum ParticipantRole { debater, judge, coach }

class LiveParticipant extends Equatable {
  final String id;
  final String name;
  final ParticipantRole role;
  final TeamSide? team;
  final bool isMicOn;
  final bool isCameraOn;
  final bool isActiveSpeaker;
  final int? currentScore;

  const LiveParticipant({
    required this.id,
    required this.name,
    required this.role,
    this.team,
    this.isMicOn = false,
    this.isCameraOn = false,
    this.isActiveSpeaker = false,
    this.currentScore,
  });

  LiveParticipant copyWith({
    String? id,
    String? name,
    ParticipantRole? role,
    TeamSide? team,
    bool? isMicOn,
    bool? isCameraOn,
    bool? isActiveSpeaker,
    int? currentScore,
  }) =>
      LiveParticipant(
        id: id ?? this.id,
        name: name ?? this.name,
        role: role ?? this.role,
        team: team ?? this.team,
        isMicOn: isMicOn ?? this.isMicOn,
        isCameraOn: isCameraOn ?? this.isCameraOn,
        isActiveSpeaker: isActiveSpeaker ?? this.isActiveSpeaker,
        currentScore: currentScore ?? this.currentScore,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        role,
        team,
        isMicOn,
        isCameraOn,
        isActiveSpeaker,
        currentScore,
      ];
}

class POIRequest extends Equatable {
  final String id;
  final String debaterId;
  final String debaterName;
  final TeamSide team;
  final DateTime createdAt;

  const POIRequest({
    required this.id,
    required this.debaterId,
    required this.debaterName,
    required this.team,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, debaterId, debaterName, team, createdAt];
}

class PrepChatMessage extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  const PrepChatMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.isMine = false,
  });

  @override
  List<Object?> get props => [id, authorId, authorName, text, createdAt, isMine];
}

class PrivateNote extends Equatable {
  final String id;
  final String fromName;
  final String toName;
  final String text;
  final DateTime createdAt;
  final bool fromMe;

  const PrivateNote({
    required this.id,
    required this.fromName,
    required this.toName,
    required this.text,
    required this.createdAt,
    this.fromMe = false,
  });

  @override
  List<Object?> get props => [id, fromName, toName, text, createdAt, fromMe];
}

class ActivityEvent extends Equatable {
  final String id;
  final DateTime timestamp;
  final String description;

  const ActivityEvent({
    required this.id,
    required this.timestamp,
    required this.description,
  });

  @override
  List<Object?> get props => [id, timestamp, description];
}

class JoinRequest extends Equatable {
  final String id;
  final String debaterName;
  final DateTime createdAt;

  const JoinRequest({
    required this.id,
    required this.debaterName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, debaterName, createdAt];
}
