class BlogReactionRequest {
  final String type;
  BlogReactionRequest({required this.type});
  Map<String, dynamic> toJson() => {'type': type};
}