import 'package:equatable/equatable.dart';

class MotionEntity extends Equatable {
  final String title;
  final List<String> topics;

  const MotionEntity({required this.title, required this.topics});
  @override
  List<Object?> get props => [title, topics];
}
