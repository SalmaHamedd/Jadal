import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/domain/entities/blog_author_option.dart';
import 'package:jadal_app/features/blog/domain/entities/blog_details.dart';
import 'package:jadal_app/features/blog/domain/entities/category.dart';
import 'package:jadal_app/features/blog/domain/entities/tag.dart';

abstract class BlogRepository {
  Future<Either<Failure, List<Blog>>> getBlogs({
    int page = 1,
    int perPage = 15,
  });

  /// `GET /blog?q=&category_id[]=&tag_id[]=&publisher_id[]=&liked_by_me=`
  /// (sprinkles §10) — extends the same list endpoint, same response shape.
  Future<Either<Failure, List<Blog>>> searchBlogs({
    String? q,
    List<int> categoryIds,
    List<int> tagIds,
    int? publisherId,
    bool? likedByMe,
    int page = 1,
    int perPage = 15,
  });

  /// `GET /blog/authors` — users with at least one published post.
  Future<Either<Failure, List<BlogAuthorOption>>> getAuthors();

  Future<Either<Failure, BlogDetails>> getBlogDetails(String slug);

  Future<Either<Failure, Map<String, int>>> reactToBlog({
    required int blogId,
    required String type,
  });

  Future<Either<Failure, BlogDetails>> createBlog({
    required String title,
    required String content,
    File? coverImageUrl,
    List<int>? categoryIds,
    List<int>? tagIds,
  });

  Future<Either<Failure, List<Category>>> getCategories();

  Future<Either<Failure, List<Tag>>> getTags();

  Future<Either<Failure, void>> deleteBlog(int blogId);
}
