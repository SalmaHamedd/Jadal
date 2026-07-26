/// Filter params for `GET /blog?...` search (sprinkles §10).
class BlogSearchFilter {
  final String? q;
  final List<int> categoryIds;
  final List<int> tagIds;
  final int? publisherId;
  final bool likedByMe;

  const BlogSearchFilter({
    this.q,
    this.categoryIds = const [],
    this.tagIds = const [],
    this.publisherId,
    this.likedByMe = false,
  });

  bool get isEmpty =>
      (q == null || q!.isEmpty) && categoryIds.isEmpty && tagIds.isEmpty && publisherId == null && !likedByMe;

  BlogSearchFilter copyWith({
    String? q,
    List<int>? categoryIds,
    List<int>? tagIds,
    int? publisherId,
    bool clearPublisher = false,
    bool? likedByMe,
  }) =>
      BlogSearchFilter(
        q: q ?? this.q,
        categoryIds: categoryIds ?? this.categoryIds,
        tagIds: tagIds ?? this.tagIds,
        publisherId: clearPublisher ? null : (publisherId ?? this.publisherId),
        likedByMe: likedByMe ?? this.likedByMe,
      );
}
