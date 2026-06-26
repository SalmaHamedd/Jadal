import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/blog/data/models/blog_details_model.dart';
import 'package:jadal_app/features/blog/data/models/blog_reaction_request.dart';
import 'package:jadal_app/features/blog/data/models/blog_reaction_response.dart';
import 'package:jadal_app/features/blog/data/models/category_model.dart';
import 'package:jadal_app/features/blog/data/models/tag_model.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/domain/entities/blog_details.dart';
import 'package:jadal_app/features/blog/domain/entities/category.dart';
import 'package:jadal_app/features/blog/domain/entities/tag.dart';
import 'package:jadal_app/features/blog/domain/repositories/blog_repository.dart';
import 'package:jadal_app/features/blog/data/models/blog_model.dart';

class BlogRepositoryImpl implements BlogRepository {
  final http.Client client;

  BlogRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<Either<Failure, List<Blog>>> getBlogs({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final uri = Uri.parse(ApiConstants.blogUrl).replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
      );

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final List<dynamic> data = json['data'];
          final blogs = data.map((item) => BlogModel.fromJson(item)).toList();
          return Right(blogs);
        } else {
          return Left(ServerFailure(json['message'] ?? 'Failed to load blogs'));
        }
      } else if (response.statusCode == 401) {
        return Left(AuthFailure('Unauthenticated'));
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, BlogDetails>> getBlogDetails(String slug) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse('${ApiConstants.blogUrl}/$slug'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final details = BlogDetailsModel.fromJson(json);
          return Right(details);
        } else {
          return Left(
            ServerFailure(json['message'] ?? 'Failed to load article'),
          );
        }
      } else if (response.statusCode == 401) {
        return Left(AuthFailure('Unauthenticated'));
      } else if (response.statusCode == 404) {
        return Left(ServerFailure('Article not found'));
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> reactToBlog({
    required int blogId,
    required String type,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.post(
        Uri.parse('${ApiConstants.blogUrl}/$blogId/react'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'type': type}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final data = json['data'];
          return Right({
            'likes_count': data['likes_count'],
            'dislikes_count': data['dislikes_count'],
          });
        } else {
          return Left(ServerFailure(json['message'] ?? 'Reaction failed'));
        }
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, BlogDetails>> createBlog({
    required String title,
    required String content,
    String? coverImageUrl,
    List<int>? categoryIds,
    List<int>? tagIds,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final Map<String, dynamic> body = {'title': title, 'content': content};

      body['cover_image_url'] = coverImageUrl;

      body['category_ids'] = categoryIds ?? [];
      body['tag_ids'] = tagIds ?? [];

      final response = await client.post(
        Uri.parse(ApiConstants.blogUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final data = json['data'];
          final blogDetails = BlogDetailsModel.fromJson({'data': data});
          return Right(blogDetails);
        } else {
          return Left(
            ServerFailure(json['message'] ?? 'Failed to create blog'),
          );
        }
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.categoriesUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final data = json['data'] as List;
          final categories = data
              .map((item) => CategoryModel.fromJson(item))
              .toList();
          return Right(categories);
        } else {
          return Left(
            ServerFailure(json['message'] ?? 'Failed to load categories'),
          );
        }
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Tag>>> getTags() async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.tagsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final data = json['data'] as List;
          final tags = data.map((item) => TagModel.fromJson(item)).toList();
          return Right(tags);
        } else {
          return Left(ServerFailure(json['message'] ?? 'Failed to load tags'));
        }
      } else {
        return Left(ServerFailure('Server error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
