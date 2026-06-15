class BlogReactionResponse {
  final int likesCount;
  final int dislikesCount;
  BlogReactionResponse.fromJson(Map<String, dynamic> json)
      : likesCount = json['likes_count'],
        dislikesCount = json['dislikes_count'];
}