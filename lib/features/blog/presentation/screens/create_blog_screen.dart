import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
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
  final _coverImageController = TextEditingController();

  List<Category> _selectedCategories = [];
  List<Tag> _selectedTags = [];

  late CreateBlogCubit _cubit;
  late final Future<Map<String, List<dynamic>>> _metaFuture;

  @override
  void initState() {
    super.initState();
    final repository = BlogRepositoryImpl();
    _cubit = CreateBlogCubit(repository);
    _metaFuture = _fetchMeta();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _coverImageController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<Map<String, List<dynamic>>> _fetchMeta() async {
    final repository = BlogRepositoryImpl();
    final categoriesResult = await repository.getCategories();
    final tagsResult = await repository.getTags();

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
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () {
                    onConfirm(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('تأكيد'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء مقال جديد'),
        foregroundColor: Colors.white,
        elevation: 0,
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
                        'خطأ في تحميل الخيارات: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _metaFuture = _fetchMeta();
                          });
                        },
                        child: const Text('إعادة المحاولة'),
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
                    const Text(
                      'أضف مقالك الجديد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سيتم إرسال المقال للمراجعة قبل النشر',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    AuthTextField(
                      label: 'عنوان المقال *',
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
                          hintText: 'المحتوى *',
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            color: isDark
                                ? JadalColors.darkTextSecondary
                                : Colors.grey[500],
                            fontSize: context.fontSize(
                              12.5,
                              min: 11.5,
                              max: 15,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                          fontSize: context.fontSize(12.5, min: 11.5, max: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'رابط الصورة (اختياري)',
                      icon: Icons.image,
                      controller: _coverImageController,
                    ),
                    const SizedBox(height: 16),

                    MultiSelectField<Category>(
                      label: 'التصنيفات (اختياري)',
                      selectedItems: _selectedCategories,
                      displayName: (c) => c.name,
                      onTap: () {
                        _showMultiSelectDialog(
                          items: categories,
                          selectedItems: _selectedCategories,
                          title: 'اختر التصنيفات',
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
                      label: 'الوسوم (اختياري)',
                      selectedNames: _selectedTags.map((t) => t.name).toList(),
                      onTap: () {
                        _showMultiSelectDialog(
                          items: tags,
                          selectedItems: _selectedTags,
                          title: 'اختر الوسوم',
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
                      text: 'نشر المقال',
                      isLoading: state is CreateBlogLoading,
                      onPressed: () {
                        final title = _titleController.text.trim();
                        final content = _contentController.text.trim();
                        if (title.isEmpty || content.isEmpty) {
                          JadalSnackBar.show(
                            context,
                            'العنوان والمحتوى مطلوبان',
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
                          coverImageUrl:
                              _coverImageController.text.trim().isEmpty
                              ? null
                              : _coverImageController.text.trim(),
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
                style: TextStyle(
                  color: selectedNames.isEmpty
                      ? (isDark
                            ? JadalColors.darkTextSecondary
                            : Colors.grey[600])
                      : (isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary),
                  fontSize: context.fontSize(12.5, min: 11.5, max: 15),
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
