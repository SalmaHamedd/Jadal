/// One entry of the `PUT /teams/{id}/members/priority` request body.
class TeamMemberPriority {
  final int userId;
  final int priority;

  const TeamMemberPriority({required this.userId, required this.priority});

  Map<String, dynamic> toJson() => {'user_id': userId, 'priority': priority};
}
