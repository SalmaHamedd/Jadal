import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/domain/entities/blog_details.dart';
import 'package:jadal_app/features/blog/domain/entities/category.dart';
import 'package:jadal_app/features/blog/domain/entities/tag.dart';

abstract class BlogRepository {
  Future<Either<Failure, List<Blog>>> getBlogs({
    int page = 1,
    int perPage = 15,
  });

  Future<Either<Failure, BlogDetails>> getBlogDetails(String slug);

  Future<Either<Failure, Map<String, int>>> reactToBlog({
    required int blogId,
    required String type,
  });

  Future<Either<Failure, BlogDetails>> createBlog({
    required String title,
    required String content,
    String? coverImageUrl,
    List<int>? categoryIds,
    List<int>? tagIds,
  });

  Future<Either<Failure, List<Category>>> getCategories();

  Future<Either<Failure, List<Tag>>> getTags();

  Future<Either<Failure, void>> deleteBlog(int blogId);
}
