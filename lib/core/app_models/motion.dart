import 'framework.dart';

class Motion {
  final int? id;
  final String text;
  final List<String> tags;
  final List<Framework> frameworks;

  const Motion({
    this.id,
    required this.text,
    this.tags = const [],
    this.frameworks = const [],
  });

  factory Motion.fromJson(Map<String, dynamic> json) => Motion(
        id: (json['id'] as num?)?.toInt(),
        text: (json['text'] ?? json['title'] ?? '').toString(),
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        frameworks: Framework.listFromJson(json['frameworks']),
      );
}
