/// How a user signs up for a debate (§15.1), sent to
/// `POST /debates/{id}/register` as the `as` field. Solo maps to the backend's
/// `debater` variant.
enum RegistrationKind {
  team('team'),
  solo('debater'),
  judge('judge');

  /// The value sent in the request body's `as` field.
  final String wire;
  const RegistrationKind(this.wire);
}

/// A typed registration request. [teamId] is only used for [RegistrationKind.team].
class DebateRegistration {
  final int debateId;
  final RegistrationKind kind;
  final int? teamId;

  const DebateRegistration({
    required this.debateId,
    required this.kind,
    this.teamId,
  });
}
