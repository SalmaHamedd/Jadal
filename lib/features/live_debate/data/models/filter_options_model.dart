/// Lightweight option-list rows for the debate/blog search filter dialogs
/// (sprinkles §8/§10) — deliberately separate from the richer domain models
/// used elsewhere (e.g. `SearchTeam`), since these are just id+name pickers.

class JudgeOption {
  final int id;
  final String name;
  final String? avatarUrl;
  const JudgeOption({required this.id, required this.name, this.avatarUrl});

  factory JudgeOption.fromJson(Map<String, dynamic> j) => JudgeOption(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
      );

  static List<JudgeOption> listFromJson(List<dynamic>? raw) =>
      (raw ?? const []).whereType<Map>().map((e) => JudgeOption.fromJson(e.cast<String, dynamic>())).toList();
}

class TeamOption {
  final int id;
  final String name;
  final bool isRandom;
  final String status;
  const TeamOption({
    required this.id,
    required this.name,
    required this.isRandom,
    required this.status,
  });

  factory TeamOption.fromJson(Map<String, dynamic> j) => TeamOption(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        isRandom: j['is_random'] as bool? ?? false,
        status: j['status'] as String? ?? '',
      );

  static List<TeamOption> listFromJson(List<dynamic>? raw) =>
      (raw ?? const []).whereType<Map>().map((e) => TeamOption.fromJson(e.cast<String, dynamic>())).toList();
}
