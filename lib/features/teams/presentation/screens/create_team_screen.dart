import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:jadal_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:jadal_app/features/search/domain/entities/search_user.dart';
import 'package:jadal_app/features/teams/domain/repositories/team_repository.dart';
import 'package:jadal_app/features/teams/presentation/cubit/create_team_cubit.dart';
import 'package:jadal_app/features/teams/presentation/widgets/user_search_picker.dart';

/// Creates a new team: name + members (searched by name), with one of the
/// picked members chosen as leader — matching `POST /teams`'s
/// `{ name, leader_id, members }` body, where `members` includes the leader.
class CreateTeamScreen extends StatefulWidget {
  final TeamRepository repository;
  const CreateTeamScreen({super.key, required this.repository});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<SearchUser> _members = [];
  int? _leaderId;
  late final CreateTeamCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = CreateTeamCubit(widget.repository);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _addMember(SearchUser user) {
    setState(() {
      _members.add(user);
      _leaderId ??= user.id;
    });
  }

  void _removeMember(SearchUser user) {
    setState(() {
      _members.removeWhere((m) => m.id == user.id);
      if (_leaderId == user.id) {
        _leaderId = _members.isEmpty ? null : _members.first.id;
      }
    });
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_members.length < 2) {
      JadalSnackBar.show(context, 'أضف عضوين على الأقل', type: SnackBarType.warning);
      return;
    }
    if (_leaderId == null) {
      JadalSnackBar.show(context, 'اختر قائداً للفريق', type: SnackBarType.warning);
      return;
    }
    context.read<CreateTeamCubit>().submit(
          name: _nameController.text.trim(),
          leaderId: _leaderId!,
          memberIds: _members.map((m) => m.id).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateTeamCubit>.value(
      value: _cubit,
      child: JadalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'فريق جديد',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: BlocConsumer<CreateTeamCubit, CreateTeamState>(
            listener: (context, state) {
              if (state is CreateTeamSuccess) {
                JadalSnackBar.show(context, 'تم إنشاء الفريق بنجاح', type: SnackBarType.success);
                Navigator.pop(context, true);
              } else if (state is CreateTeamError) {
                JadalSnackBar.show(context, state.message, type: SnackBarType.error);
              }
            },
            builder: (context, state) {
              final submitting = state is CreateTeamSubmitting;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return SingleChildScrollView(
                padding: EdgeInsets.all(context.wp(5)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        label: 'اسم الفريق',
                        icon: Icons.groups_rounded,
                        controller: _nameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'اسم الفريق مطلوب' : null,
                      ),
                      SizedBox(height: context.hp(2.5)),
                      Text(
                        'الأعضاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? JadalColors.darkTextPrimary : JadalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'أضف عضوين على الأقل، ثم اختر قائد الفريق من بينهم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: JadalColors.judgesGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      UserSearchPicker(
                        excludeIds: _members.map((m) => m.id).toSet(),
                        onSelected: _addMember,
                      ),
                      if (_members.isNotEmpty) ...[
                        SizedBox(height: context.hp(2)),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _members.map((m) {
                            final isLeader = m.id == _leaderId;
                            return InputChip(
                              label: Text(
                                isLeader ? '${m.name} (قائد)' : m.name,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: isLeader ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              avatar: Icon(
                                isLeader ? Icons.star_rounded : Icons.person_outline,
                                size: 16,
                                color: isLeader ? JadalColors.primaryOrange : null,
                              ),
                              selected: isLeader,
                              selectedColor: JadalColors.primaryOrange.withValues(alpha: 0.15),
                              onSelected: (_) => setState(() => _leaderId = m.id),
                              onDeleted: () => _removeMember(m),
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: context.hp(4)),
                      AuthButton(
                        text: 'إنشاء الفريق',
                        isLoading: submitting,
                        onPressed: submitting ? null : () => _submit(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
