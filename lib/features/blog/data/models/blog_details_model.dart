import 'package:jadal_app/features/blog/domain/entities/blog_details.dart';
import 'author_model.dart';
import 'category_model.dart';
import 'tag_model.dart';

class BlogDetailsModel extends BlogDetails {
  const BlogDetailsModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.content,
    super.coverImageUrl,
    required super.author,
    required super.categories,
    required super.tags,
    required super.views,
    required super.likesCount,
    required super.dislikesCount,
    required super.status,
    super.reviewerComment,
    required super.publishedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BlogDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return BlogDetailsModel(
      id: data['id'],
      title: data['title'],
      slug: data['slug'],
      content: data['content'],
      coverImageUrl: data['cover_image_url'],
      author: AuthorModel.fromJson(data['author']),
      categories: (data['categories'] as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList(),
      tags: (data['tags'] as List)
          .map((t) => TagModel.fromJson(t))
          .toList(),
      views: data['views'],
      likesCount: data['likes_count'],
      dislikesCount: data['dislikes_count'],
      status: data['status'],
      reviewerComment: data['reviewer_comment'],
      publishedAt: DateTime.parse(data['published_at']),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }
}