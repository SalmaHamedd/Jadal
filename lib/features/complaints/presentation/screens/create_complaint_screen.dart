import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/extensions/responsive_extension.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/core/widgets/jadal_snack_bar.dart';
import 'package:jadal_app/features/complaints/domain/repositories/complaint_repository.dart';
import 'package:jadal_app/features/complaints/presentation/cubit/create_complaint_cubit.dart';
import 'package:jadal_app/features/complaints/presentation/widgets/debate_picker_field.dart';
import 'package:jadal_app/features/live_debate/data/models/debate_list_model.dart';

/// Files a new complaint about a debate — `POST /complaints`. Reached either
/// from "My Complaints" (picks a debate via search) or directly from a
/// debate's details screen with [initialDebateId]/[initialDebateTitle] set,
/// which locks the debate field to that debate instead of showing the picker.
class CreateComplaintScreen extends StatefulWidget {
  final ComplaintRepository repository;
  final int? initialDebateId;
  final String? initialDebateTitle;

  const CreateComplaintScreen({
    super.key,
    required this.repository,
    this.initialDebateId,
    this.initialDebateTitle,
  });

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DebateListItem? _debate;
  late final CreateComplaintCubit _cubit;

  bool get _isDebateLocked => widget.initialDebateId != null;
  int? get _debateId => widget.initialDebateId ?? _debate?.id;
  String? get _debateTitle => widget.initialDebateTitle ?? _debate?.title;

  @override
  void initState() {
    super.initState();
    _cubit = CreateComplaintCubit(widget.repository);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_debateId == null) {
      JadalSnackBar.show(
        context,
        context.loc.complaintChooseDebate,
        type: SnackBarType.warning,
      );
      return;
    }
    context.read<CreateComplaintCubit>().submit(
      description: _descriptionController.text.trim(),
      debateId: _debateId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateComplaintCubit>.value(
      value: _cubit,
      child: JadalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              context.loc.complaintNewComplaint,
              style: AppTextStyles.title(context),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: BlocConsumer<CreateComplaintCubit, CreateComplaintState>(
            listener: (context, state) {
              if (state is CreateComplaintSuccess) {
                JadalSnackBar.show(
                  context,
                  context.loc.complaintSubmittedSuccess,
                  type: SnackBarType.success,
                );
                Navigator.pop(context, true);
              } else if (state is CreateComplaintError) {
                JadalSnackBar.show(
                  context,
                  state.message,
                  type: SnackBarType.error,
                );
              }
            },
            builder: (context, state) {
              final submitting = state is CreateComplaintSubmitting;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return SingleChildScrollView(
                padding: EdgeInsets.all(context.wp(5)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.complaintDebateFieldLabel,
                        style: AppTextStyles.bodyEmphasis(context).copyWith(
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isDebateLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? JadalColors.darkSurfaceElevated
                                : const Color(0xFFF1F4F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 18,
                                color: JadalColors.primaryBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _debateTitle ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? JadalColors.darkTextPrimary
                                        : JadalColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DebatePickerField(
                          selected: _debate,
                          onChanged: (debate) =>
                              setState(() => _debate = debate),
                        ),
                      SizedBox(height: context.hp(2.5)),
                      Text(
                        context.loc.complaintDescriptionLabel,
                        style: AppTextStyles.bodyEmphasis(context).copyWith(
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: AppTextStyles.body(context).copyWith(
                          color: isDark
                              ? JadalColors.darkTextPrimary
                              : JadalColors.lightTextPrimary,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? context.loc.complaintDescriptionRequired
                            : null,
                        decoration: InputDecoration(
                          hintText: context.loc.complaintDescriptionHint,
                          hintStyle: AppTextStyles.body(
                            context,
                          ).copyWith(color: JadalColors.judgesGrey),
                          filled: true,
                          fillColor: isDark
                              ? JadalColors.darkSurfaceElevated
                              : const Color(0xFFF1F4F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      SizedBox(height: context.hp(4)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting ? null : () => _submit(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JadalColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.loc.complaintSubmitButton,
                                  style: AppTextStyles.button(
                                    context,
                                  ).copyWith(color: Colors.white),
                                ),
                        ),
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
