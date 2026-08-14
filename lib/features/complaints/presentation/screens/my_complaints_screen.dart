import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jadal_app/core/localization/l10n/context_localiztion.dart';
import 'package:jadal_app/core/storage/preferences_database.dart';
import 'package:jadal_app/core/theme/app_colors.dart';
import 'package:jadal_app/core/theme/app_text_styles.dart';
import 'package:jadal_app/core/widgets/jadal_gradient_background.dart';
import 'package:jadal_app/di/injection_container.dart' as di;
import 'package:jadal_app/features/complaints/data/repositories/complaint_repository_impl.dart';
import 'package:jadal_app/features/complaints/domain/entities/complaint.dart';
import 'package:jadal_app/features/complaints/domain/repositories/complaint_repository.dart';
import 'package:jadal_app/features/complaints/presentation/cubit/complaint_cubit.dart';
import 'package:jadal_app/features/complaints/presentation/screens/create_complaint_screen.dart';
import 'package:jadal_app/features/live_debate/data/repositories/live_debate_repository.dart';
import 'package:jadal_app/features/live_debate/domain/debate_search_filter.dart';
import 'package:jadal_app/core/error/failure_text.dart';
import 'package:jadal_app/core/widgets/jadal_error_view.dart';

/// The caller's own complaints — `GET /complaints/mine`. The endpoint only
/// returns `debate_id`, so this separately loads the caller's own debate
/// history (the same data the profile's "latest debates" section uses) to
/// resolve each complaint's debate title for display.
class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  Map<int, String> _debateTitles = const {};

  @override
  void initState() {
    super.initState();
    _loadDebateTitles();
  }

  Future<void> _loadDebateTitles() async {
    final userId = await PreferencesDatabase().getValue<int>('user_id');
    if (userId == null) return;
    final result = await di.sl<LiveDebateRepository>().searchDebates(
      DebateSearchFilter(userIds: [userId]),
      perPage: 100,
    );
    if (!mounted) return;
    result.fold((_) {}, (page) {
      setState(() {
        _debateTitles = {for (final d in page.items) d.id: d.title};
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ComplaintRepository repository = ComplaintRepositoryImpl();

    return BlocProvider(
      create: (_) => ComplaintCubit(repository)..loadMyComplaints(),
      child: Builder(
        builder: (context) {
          return JadalGradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  context.loc.drawerMyComplaints,
                  style: AppTextStyles.title(context),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: JadalColors.primaryOrange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(
                  context.loc.complaintNewComplaint,
                  style: AppTextStyles.button(
                    context,
                  ).copyWith(color: Colors.white),
                ),
                onPressed: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateComplaintScreen(repository: repository),
                    ),
                  );
                  if (created == true && context.mounted) {
                    context.read<ComplaintCubit>().loadMyComplaints();
                  }
                },
              ),
              body: BlocBuilder<ComplaintCubit, ComplaintState>(
                builder: (context, state) {
                  if (state is ComplaintLoading || state is ComplaintInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ComplaintLoaded) {
                    final complaints = state.complaints;
                    if (complaints.isEmpty) {
                      return RefreshIndicator(
                        color: JadalColors.primaryOrange,
                        onRefresh: () =>
                            context.read<ComplaintCubit>().loadMyComplaints(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                context.loc.complaintNoneYet,
                                style: AppTextStyles.subtitle(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: JadalColors.primaryOrange,
                      onRefresh: () =>
                          context.read<ComplaintCubit>().loadMyComplaints(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: complaints.length,
                        itemBuilder: (context, index) => _ComplaintCard(
                          complaint: complaints[index],
                          debateTitle:
                              _debateTitles[complaints[index].debateId],
                        ),
                      ),
                    );
                  } else if (state is ComplaintError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          JadalErrorView(
                            message: FailureText.fromMessage(
                              context,
                              state.message,
                            ),
                            onRetry: () => context
                                .read<ComplaintCubit>()
                                .loadMyComplaints(),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final String? debateTitle;
  const _ComplaintCard({required this.complaint, this.debateTitle});

  String _statusLabel(BuildContext context) => switch (complaint.status) {
    'open' => context.loc.complaintStatusOpen,
    'resolved' => context.loc.complaintStatusResolved,
    'rejected' => context.loc.complaintStatusRejected,
    'closed' => context.loc.complaintStatusClosed,
    _ => complaint.status,
  };

  Color _statusColor() => switch (complaint.status) {
    'open' => JadalColors.primaryBlue,
    'resolved' => JadalColors.positiveGreen,
    'rejected' => JadalColors.negativeRed,
    _ => JadalColors.judgesGrey,
  };

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _statusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? JadalColors.darkSurface : JadalColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? JadalColors.darkSurfaceElevated
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JadalColors.negativeRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.report_gmailerrorred_rounded,
                    color: JadalColors.negativeRed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    debateTitle ??
                        context.loc.complaintDebateFallback(complaint.debateId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyEmphasis(context).copyWith(
                      color: isDark
                          ? JadalColors.darkTextPrimary
                          : JadalColors.lightTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(context),
                    style: AppTextStyles.small(context).copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              complaint.description,
              style: AppTextStyles.body(context).copyWith(
                color: isDark
                    ? JadalColors.darkTextSecondary
                    : JadalColors.lightTextSecondary,
              ),
            ),
            if (complaint.adminResponse != null &&
                complaint.adminResponse!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JadalColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.complaintAdminResponseLabel,
                      style: AppTextStyles.small(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: JadalColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.adminResponse!,
                      style: AppTextStyles.caption(context).copyWith(
                        color: isDark
                            ? JadalColors.darkTextPrimary
                            : JadalColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(complaint.createdAt),
              style: AppTextStyles.small(
                context,
              ).copyWith(color: JadalColors.judgesGrey),
            ),
          ],
        ),
      ),
    );
  }
}
