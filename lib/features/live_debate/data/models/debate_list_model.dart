import '../../../../core/app_models/debate_format_model.dart';
import '../../../../core/app_models/motion.dart';
import '../../../../core/function/json_utils.dart';
import '../../domain/debate_status.dart';

/// One lightweight item from `GET /debates?status=…` (§13). Enough for a list
/// card; the detail screen fetches `live-state` for the full picture. The list
/// `motion` is **minimal** (id + text only — no tags/frameworks) and the item
/// carries **no result/winner**.
class DebateListItem {
  final int id;
  final String title;
  final String? tag;
  final DebateStatus status;
  final String? cancellationReason;
  final String? livekitRoomName;
  final DebateFormatModel format;
  final Motion? motion;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;

  const DebateListItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.status,
    required this.cancellationReason,
    required this.livekitRoomName,
    required this.format,
    required this.motion,
    required this.scheduledAt,
    required this.startedAt,
    required this.endedAt,
    required this.createdAt,
  });

  factory DebateListItem.fromJson(Map<String, dynamic> j) => DebateListItem(
        id: asInt(j['id']) ?? 0,
        title: asString(j['title']) ?? '',
        tag: asString(j['tag']),
        status: DebateStatus.fromWire(asString(j['status'])),
        cancellationReason: asString(j['cancellation_reason']),
        livekitRoomName: asString(j['livekit_room_name']),
        format: DebateFormatModel.fromDebateList(asMap(j['format']) ?? const {}),
        motion: asMap(j['motion']) == null ? null : Motion.fromJson(asMap(j['motion'])!),
        scheduledAt: asDate(j['scheduled_at']),
        startedAt: asDate(j['started_at']),
        endedAt: asDate(j['ended_at']),
        createdAt: asDate(j['created_at']),
      );
}

/// `meta` block from the paginated list response.
class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic>? j) => PaginationMeta(
        currentPage: asInt(j?['current_page']) ?? 1,
        lastPage: asInt(j?['last_page']) ?? 1,
        perPage: asInt(j?['per_page']) ?? 15,
        total: asInt(j?['total']) ?? 0,
      );

  bool get hasMore => currentPage < lastPage;
}

/// One page of `GET /debates` — the items plus pagination metadata.
class DebateListPage {
  final List<DebateListItem> items;
  final PaginationMeta meta;

  const DebateListPage({required this.items, required this.meta});

  factory DebateListPage.fromEnvelope(Map<String, dynamic> body) => DebateListPage(
        items: asMapList(body['data']).map(DebateListItem.fromJson).toList(),
        meta: PaginationMeta.fromJson(asMap(body['meta'])),
      );
}
