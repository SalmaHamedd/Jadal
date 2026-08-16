import '../../../../core/function/json_utils.dart';

/// Models for the registration endpoints: the team picker and the
/// registrant lists.

/// One team the caller may register for a debate, with its eligibility.
class RegisterableTeam {
  final int id;
  final String name;
  final int membersCount;
  final bool eligible;

  /// `already_registered` · `too_few_members` · `registration_closed` (or null).
  final String? ineligibleReason;

  const RegisterableTeam({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.eligible,
    this.ineligibleReason,
  });

  factory RegisterableTeam.fromJson(Map<String, dynamic> j) => RegisterableTeam(
        id: asInt(j['id']) ?? 0,
        name: asString(j['name']) ?? '',
        membersCount: asInt(j['members_count']) ?? 0,
        eligible: asBool(j['eligible']),
        ineligibleReason: asString(j['ineligible_reason']),
      );
}

/// Response of `GET /debates/{id}/registerable-teams`.
class RegisterableTeams {
  final int debateId;
  final int? alreadyRegisteredTeamId;
  final List<RegisterableTeam> teams;

  const RegisterableTeams({
    required this.debateId,
    this.alreadyRegisteredTeamId,
    required this.teams,
  });

  factory RegisterableTeams.fromJson(Map<String, dynamic> j) => RegisterableTeams(
        debateId: asInt(j['debate_id']) ?? 0,
        alreadyRegisteredTeamId: asInt(j['already_registered_team_id']),
        teams: asMapList(j['teams']).map(RegisterableTeam.fromJson).toList(),
      );
}

/// A registered team row.
class RegistrantTeam {
  final int teamId;
  final String teamName;
  final int membersCount;
  final String? registeredAt;

  const RegistrantTeam({
    required this.teamId,
    required this.teamName,
    required this.membersCount,
    this.registeredAt,
  });

  factory RegistrantTeam.fromJson(Map<String, dynamic> j) {
    final team = asMap(j['team']);
    return RegistrantTeam(
      teamId: asInt(team?['id']) ?? 0,
      teamName: asString(team?['name']) ?? '',
      membersCount: asInt(j['members_count']) ?? 0,
      registeredAt: asString(j['registered_at']),
    );
  }
}

/// A registered individual (judge or solo applicant) row.
class RegistrantUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? registeredAt;

  const RegistrantUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.registeredAt,
  });

  factory RegistrantUser.fromJson(Map<String, dynamic> j) {
    final user = asMap(j['user']) ?? j;
    return RegistrantUser(
      id: asInt(user['id']) ?? 0,
      name: asString(user['name']) ?? '',
      avatarUrl: asString(user['avatar_url']),
      registeredAt: asString(j['registered_at']),
    );
  }
}

/// Response of `GET /debates/{id}/registrations`.
class DebateRegistrations {
  final List<RegistrantTeam> teams;
  final List<RegistrantUser> judges;
  final List<RegistrantUser> solo;

  const DebateRegistrations({
    required this.teams,
    required this.judges,
    required this.solo,
  });

  factory DebateRegistrations.fromJson(Map<String, dynamic> j) => DebateRegistrations(
        teams: asMapList(j['teams']).map(RegistrantTeam.fromJson).toList(),
        judges: asMapList(j['judges']).map(RegistrantUser.fromJson).toList(),
        solo: asMapList(j['solo']).map(RegistrantUser.fromJson).toList(),
      );

  bool get isEmpty => teams.isEmpty && judges.isEmpty && solo.isEmpty;
}
