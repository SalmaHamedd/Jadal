/// A persisted team-chat message from `GET/POST /debates/{id}/chat`.
/// `seenBy` always includes the sender; the unread dot is derived as
/// "my user id ∉ seenBy" — see [LiveDebateCubit.unreadTeamChatCount].
class TeamChatHistoryMessage {
  final int id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime sentAt;
  final List<String> seenBy;

  const TeamChatHistoryMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
    required this.seenBy,
  });

  factory TeamChatHistoryMessage.fromJson(Map<String, dynamic> j) => TeamChatHistoryMessage(
        id: (j['id'] as num?)?.toInt() ?? 0,
        senderId: '${j['sender_id']}',
        senderName: j['sender_name'] as String? ?? '',
        message: j['message'] as String? ?? '',
        sentAt: DateTime.tryParse(j['sent_at'] as String? ?? '') ?? DateTime.now(),
        seenBy: ((j['seen_by'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
      );

  static List<TeamChatHistoryMessage> listFromJson(Map<String, dynamic> data) =>
      ((data['messages'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => TeamChatHistoryMessage.fromJson(e.cast<String, dynamic>()))
          .toList();
}
