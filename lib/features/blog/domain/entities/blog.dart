import 'package:jadal_app/features/blog/domain/entities/author.dart';
import 'package:jadal_app/features/blog/domain/entities/category.dart';
import 'package:jadal_app/features/blog/domain/entities/tag.dart';

class Blog {
  final int id;
  final String title;
  final String slug;
  final String excerpt;
  final String? coverImageUrl;
  final Author author;
  final List<Category> categories;
  final List<Tag> tags;
  final int views;
  final int likesCount;
  final int dislikesCount;
  final String status;
  final DateTime publishedAt;
  final DateTime createdAt;

  const Blog({
    required this.id,
    required this.title,
    required this.slug,
    required this.excerpt,
    this.coverImageUrl,
    required this.author,
    required this.categories,
    required this.tags,
    required this.views,
    required this.likesCount,
    required this.dislikesCount,
    required this.status,
    required this.publishedAt,
    required this.createdAt,
  });
}