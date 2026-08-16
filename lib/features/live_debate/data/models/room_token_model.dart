import '../../../../core/function/json_utils.dart';
import '../../domain/debate_room_role.dart';

/// Response of `GET /debates/{id}/token?room={main|prop|opp|result}`.
/// Tokens are **room-scoped** (fetch a fresh one on every room switch) with a
/// 2-hour TTL. Gate the UI on [roleInRoom] — not the user's global role.
class RoomTokenModel {
  final String token;
  final String url;
  final String roomName;
  final DebateRoomRole roleInRoom;

  const RoomTokenModel({
    required this.token,
    required this.url,
    required this.roomName,
    required this.roleInRoom,
  });

  factory RoomTokenModel.fromJson(Map<String, dynamic> json) => RoomTokenModel(
        token: asString(json['token']) ?? '',
        url: asString(json['url']) ?? '',
        roomName: asString(json['room_name']) ?? '',
        roleInRoom: DebateRoomRole.fromWire(asString(json['role_in_room'])),
      );
}
