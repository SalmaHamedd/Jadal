import '../app_entities/motion_entity.dart';

class MotionModel extends MotionEntity {
  const MotionModel({required super.title, required super.topics});
  factory MotionModel.fromJson(Map<String, dynamic> json) {
    List<String> topics = [];
    json['topics'].forEach((topic) {
      topics.add(topic);
    });
    return MotionModel(title: json['title'], topics: topics);
  }

  Map<String, dynamic> toJson() {
    return {'email': title, 'password': topics};
  }
}
