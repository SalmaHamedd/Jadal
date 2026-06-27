class Framework {
  final int id;
  final String name;

  final String? colorHex;

  const Framework({required this.id, required this.name, this.colorHex});

  factory Framework.fromJson(Map<String, dynamic> json) => Framework(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? '').toString(),
        colorHex: json['color_hex'] as String?,
      );

  static List<Framework> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Framework.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
