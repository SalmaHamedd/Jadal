import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/data/models/author_model.dart';
import 'package:jadal_app/features/blog/data/models/category_model.dart';
import 'package:jadal_app/features/blog/data/models/tag_model.dart';

class BlogModel extends Blog {
  const BlogModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.excerpt,
    super.coverImageUrl,
    required super.author,
    required super.categories,
    required super.tags,
    required super.views,
    required super.likesCount,
    required super.dislikesCount,
    required super.status,
    required super.publishedAt,
    required super.createdAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      excerpt: json['excerpt'],
      coverImageUrl: json['cover_image_url'],
      author: AuthorModel.fromJson(json['author']),
      categories: (json['categories'] as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList(),
      tags: (json['tags'] as List).map((t) => TagModel.fromJson(t)).toList(),
      views: json['views'],
      likesCount: json['likes_count'],
      dislikesCount: json['dislikes_count'],
      status: json['status'],
      publishedAt: DateTime.parse(json['published_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}