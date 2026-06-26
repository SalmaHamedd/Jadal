import 'package:equatable/equatable.dart';
import 'author.dart';
import 'category.dart';
import 'tag.dart';

class BlogDetails extends Equatable {
  final int id;
  final String title;
  final String slug;
  final String content;
  final String? coverImageUrl;
  final Author author;
  final List<Category> categories;
  final List<Tag> tags;
  final int views;
  final int likesCount;
  final int dislikesCount;
  final String status;
  final String? reviewerComment;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BlogDetails({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    this.coverImageUrl,
    required this.author,
    required this.categories,
    required this.tags,
    required this.views,
    required this.likesCount,
    required this.dislikesCount,
    required this.status,
    this.reviewerComment,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    slug,
    content,
    coverImageUrl,
    author,
    categories,
    tags,
    views,
    likesCount,
    dislikesCount,
    status,
    reviewerComment,
    publishedAt,
    createdAt,
    updatedAt,
  ];
}
