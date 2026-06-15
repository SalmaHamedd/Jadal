import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/domain/entities/blog_details.dart';

abstract class BlogRepository {
  Future<Either<Failure, List<Blog>>> getBlogs({int page = 1, int perPage = 15});

  Future<Either<Failure, BlogDetails>> getBlogDetails(String slug);

  Future<Either<Failure, Map<String, int>>> reactToBlog({
    required int blogId,
    required String type, 
  });
}