import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'package:jadal_app/core/constants/api_constants.dart';
import 'package:jadal_app/core/error/failures.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/features/blog/data/models/blog_details_model.dart';
import 'package:jadal_app/features/blog/data/models/category_model.dart';
import 'package:jadal_app/features/blog/data/models/tag_model.dart';
import 'package:jadal_app/features/blog/domain/entities/blog.dart';
import 'package:jadal_app/features/blog/domain/entities/blog_author_option.dart';
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
  Future<Either<Failure, List<Blog>>> searchBlogs({
    String? q,
    List<int> categoryIds = const [],
    List<int> tagIds = const [],
    int? publisherId,
    bool? likedByMe,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final uri = Uri.parse(ApiConstants.blogUrl).replace(queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
        if (q != null && q.isNotEmpty) 'q': q,
        if (categoryIds.isNotEmpty) 'category_id[]': categoryIds.map((e) => '$e').toList(),
        if (tagIds.isNotEmpty) 'tag_id[]': tagIds.map((e) => '$e').toList(),
        if (publisherId != null) 'publisher_id[]': ['$publisherId'],
        if (likedByMe == true) 'liked_by_me': '1',
      });

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
        }
        return Left(ServerFailure(json['message'] ?? 'Failed to search blogs'));
      } else if (response.statusCode == 401) {
        return Left(AuthFailure('Unauthenticated'));
      }
      return Left(ServerFailure('Server error: ${response.statusCode}'));
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BlogAuthorOption>>> getAuthors() async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.get(
        Uri.parse(ApiConstants.blogAuthorsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final data = json['data'] as List;
          return Right(data
              .map((e) => BlogAuthorOption(id: (e['id'] as num).toInt(), name: e['name'] as String? ?? ''))
              .toList());
        }
        return Left(ServerFailure(json['message'] ?? 'Failed to load authors'));
      }
      return Left(ServerFailure('Server error: ${response.statusCode}'));
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
  File? coverImageUrl,
  List<int>? categoryIds,
  List<int>? tagIds,
}) async {
  try {
    final token = await PreferencesDatabase().getToken();
    if (token == null) return Left(AuthFailure('Not authenticated'));

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.blogUrl),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['title'] = title;
    request.fields['content'] = content;

    final ids = categoryIds ?? [];
    for (var i = 0; i < ids.length; i++) {
      request.fields['category_ids[$i]'] = ids[i].toString();
    }

    final tIds = tagIds ?? [];
    for (var i = 0; i < tIds.length; i++) {
      request.fields['tag_ids[$i]'] = tIds[i].toString();
    }

    if (coverImageUrl != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cover_image', coverImageUrl.path),
      );
    }

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    final json = jsonDecode(response.body);
    final String message = json['message'] ?? 'Unknown error';

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (json['success'] == true) {
        final data = json['data'];
        final blogDetails = BlogDetailsModel.fromJson({'data': data});
        return Right(blogDetails);
      } else {
        return Left(ServerFailure(message));
      }
    } else {
      return Left(ServerFailure(message));
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

  @override
  Future<Either<Failure, void>> deleteBlog(int blogId) async {
    try {
      final token = await PreferencesDatabase().getToken();
      if (token == null) return Left(AuthFailure('Not authenticated'));

      final response = await client.delete(
        Uri.parse('${ApiConstants.blogUrl}/$blogId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return const Right(null);
        } else {
          return Left(
            ServerFailure(json['message'] ?? 'Failed to delete blog'),
          );
        }
      } else {
        try {
          final json = jsonDecode(response.body);
          return Left(
            ServerFailure(
              json['message'] ?? 'Server error: ${response.statusCode}',
            ),
          );
        } catch (_) {
          return Left(ServerFailure('Server error: ${response.statusCode}'));
        }
      }
    } catch (e) {
      return Left(NetworkFailure('Network error: $e'));
    }
  }
}
