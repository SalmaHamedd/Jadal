import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/blog/data/repositories/blog_repository_impl.dart';
import 'package:jadal_app/features/blog/domain/entities/category.dart';
import 'package:jadal_app/features/blog/domain/entities/tag.dart';
import 'package:jadal_app/features/blog/presentation/cubit/create_blog_cubit.dart';
import 'package:jadal_app/features/blog/presentation/widgets/multi_select_field.dart';

class CreateBlogScreen extends StatefulWidget {
  const CreateBlogScreen({super.key});

  @override
  State<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  File? _coverImageFile;

  List<Category> _selectedCategories = [];
  List<Tag> _selectedTags = [];

  late final BlogRepositoryImpl _repository;
  late CreateBlogCubit _cubit;
  late final Future<Map<String, List<dynamic>>> _metaFuture;

  @override
  void initState() {
    super.initState();
    _repository = BlogRepositoryImpl();
    _cubit = CreateBlogCubit(_repository);
    _metaFuture = _fetchMeta();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _cubit.close();
    super.dispose();
  }

  static const int _maxCoverImageBytes = 8 * 1024 * 1024; // 8 MB

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final sizeInBytes = await file.length();
    if (sizeInBytes > _maxCoverImageBytes) {
      if (mounted) {
        JadalSnackBar.show(
          context,
          'حجم الصورة كبير جداً، الحد الأقصى 8 ميجابايت',
          type: SnackBarType.error,
        );
      }
      return;
    }

    setState(() {
      _coverImageFile = file;
    });
  }

  void _removeCoverImage() {
    setState(() {
      _coverImageFile = null;
    });
  }

  Future<Map<String, List<dynamic>>> _fetchMeta() async {
    final categoriesResult = await _repository.getCategories();
    final tagsResult = await _repository.getTags();

    final categories = categoriesResult.fold(
      (failure) => <Category>[],
      (data) => data,
    );
    final tags = tagsResult.fold((failure) => <Tag>[], (data) => data);
    return {'categories': categories, 'tags': tags};
  }

  Future<void> _showMultiSelectDialog({
    required List<dynamic> items,
    required List<dynamic> selectedItems,
    required String title,
    required ValueChanged<List<dynamic>> onConfirm,
  }) async {
    final tempSelected = List<dynamic>.from(selectedItems);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = tempSelected.contains(item);
                    return CheckboxListTile(
                      title: Text(item.name),
                      value: isSelected,
                      onChanged: (_) {
                        setStateDialog(() {
                          if (isSelected) {
                            tempSelected.remove(item);
                          } else {
                            tempSelected.add(item);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.loc.cancel),
                ),
                TextButton(
                  onPressed: () {
                    onConfirm(tempSelected);
                    Navigator.pop(context);
                  },
                  child: Text(context.loc.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;

    // Same package as the rest of the app: transparent app bar over the shared
    // gradient backdrop (design only — the create-blog logic is untouched).
    return JadalGradientBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(context.loc.createNewArticle, style: AppTextStyles.title(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocConsumer<CreateBlogCubit, CreateBlogState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state is CreateBlogSuccess) {
            JadalSnackBar.show(
              context,
              state.message,
              type: SnackBarType.success,
            );
            Navigator.pop(context, true);
          } else if (state is CreateBlogError) {
            JadalSnackBar.show(
              context,
              state.message,
              type: SnackBarType.error,
            );
          }
        },
        builder: (context, state) {
          return FutureBuilder<Map<String, List<dynamic>>>(
            future: _metaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.loc.optionsLoadError('${snapshot.error}'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _metaFuture = _fetchMeta();
                          });
                        },
                        child: Text(context.loc.retry),
                      ),
                    ],
                  ),
                );
              }

              final categories =
                  snapshot.data?['categories'] as List<Category>? ?? [];
              final tags = snapshot.data?['tags'] as List<Tag>? ?? [];

              return SingleChildScrollView(
                padding: EdgeInsets.all(context.wp(5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.addYourNewArticle,
                      style: AppTextStyles.headline(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.loc.articleReviewNote,
                      style: AppTextStyles.body(context).copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    AuthTextField(
                      label: context.loc.articleTitleRequiredLabel,
                      icon: Icons.title,
                      controller: _titleController,
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? JadalColors.darkSurfaceElevated
                            : const Color(0xFFF1F4F9),
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                      ),
                      child: TextFormField(
                        controller: _contentController,
                        maxLines: 8,
                        minLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: isMobile ? 14 : 16,
                          ),
                          hintText: context.loc.contentRequiredLabel,
                          hintStyle: AppTextStyles.caption(context).copyWith(
                            color: isDark
                                ? JadalColors.darkTextSecondary
                                : Colors.grey[500],
                          ),
                        ),
                        style: AppTextStyles.caption(context).copyWith(
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCoverImagePicker(isDark: isDark, isMobile: isMobile),
                    const SizedBox(height: 16),

                    MultiSelectField<Category>(
                      label: context.loc.categoriesOptionalLabel,
                      selectedItems: _selectedCategories,
                      displayName: (c) => c.name,
                      onTap: () {
                        _showMultiSelectDialog(
                          items: categories,
                          selectedItems: _selectedCategories,
                          title: context.loc.chooseCategories,
                          onConfirm: (selected) {
                            setState(() {
                              _selectedCategories = selected.cast<Category>();
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildSelectionField(
                      context: context,
                      isDark: isDark,
                      isMobile: isMobile,
                      label: context.loc.tagsOptionalLabel,
                      selectedNames: _selectedTags.map((t) => t.name).toList(),
                      onTap: () {
                        _showMultiSelectDialog(
                          items: tags,
                          selectedItems: _selectedTags,
                          title: context.loc.chooseTags,
                          onConfirm: (selected) {
                            setState(() {
                              _selectedTags = selected.cast<Tag>();
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    AuthButton(
                      text: context.loc.publishArticle,
                      isLoading: state is CreateBlogLoading,
                      onPressed: () {
                        final title = _titleController.text.trim();
                        final content = _contentController.text.trim();
                        if (title.isEmpty || content.isEmpty) {
                          JadalSnackBar.show(
                            context,
                            context.loc.titleContentRequired,
                            type: SnackBarType.error,
                          );
                          return;
                        }

                        final categoryIds = _selectedCategories
                            .map((c) => c.id)
                            .toList();
                        final tagIds = _selectedTags.map((t) => t.id).toList();

                        _cubit.createBlog(
                          title: title,
                          content: content,
                          coverImageUrl: _coverImageFile,
                          categoryIds: categoryIds,
                          tagIds: tagIds,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildCoverImagePicker({
    required bool isDark,
    required bool isMobile,
  }) {
    if (_coverImageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
            child: Image.file(
              _coverImageFile!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: _removeCoverImage,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3A55) : const Color(0xFFD8DEE7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.image,
              color: isDark ? JadalColors.darkTextSecondary : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'اختر صورة الغلاف (اختياري)',
                style: AppTextStyles.caption(context).copyWith(
                  color: isDark
                      ? JadalColors.darkTextSecondary
                      : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required BuildContext context,
    required bool isDark,
    required bool isMobile,
    required String label,
    required List<String> selectedNames,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : const Color(0xFFF1F4F9),
          borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3A55) : const Color(0xFFD8DEE7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category,
              color: isDark ? JadalColors.darkTextSecondary : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedNames.isEmpty ? label : selectedNames.join('، '),
                style: AppTextStyles.caption(context).copyWith(
                  color: selectedNames.isEmpty
                      ? (isDark
                            ? JadalColors.darkTextSecondary
                            : Colors.grey[600])
                      : (isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary),
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? JadalColors.darkTextSecondary : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
