import 'package:flutter/material.dart';

import '../../../../core/localization/widgets/locale_toggle_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/widgets/theme_toggle_button.dart';
import '../../../debates/presentation/screens/coach_monitoring_screen.dart';
import '../../../debates/presentation/screens/coach_team_screen.dart';
import '../../../debates/presentation/screens/debates_list_screen.dart';
import '../../../debates/presentation/screens/statistics_screen.dart';
import '../../../../core/mock/mock_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدال'),
        actions: const [
          LocaleToggleButton(),
          SizedBox(width: 6),
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'مرحباً بك في جدال — اختر دورك للمتابعة',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _RoleCard(
            title: 'المناظِر',
            subtitle: 'تصفّح المناظرات وانضم للجلسات',
            icon: Icons.record_voice_over,
            color: JadalColors.primaryBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DebatesListScreen()),
            ),
          ),
          _RoleCard(
            title: 'الحكم',
            subtitle: 'مناظرات متاحة للتحكيم',
            icon: Icons.gavel,
            color: JadalColors.deepBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DebatesListScreen(mode: DebatesListMode.judge),
              ),
            ),
          ),
          _RoleCard(
            title: 'المدرّب — فريقي',
            subtitle: 'إدارة الفريق، الأولويات، طلبات الانضمام',
            icon: Icons.school,
            color: JadalColors.primaryOrange,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoachTeamScreen()),
            ),
          ),
          _RoleCard(
            title: 'المدرّب — متابعة الجلسة',
            subtitle: 'مشاهدة المناظرة المباشرة وإرسال ملاحظات',
            icon: Icons.podcasts,
            color: JadalColors.primaryOrange,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => CoachMonitoringScreen(debate: mockDebates[1])),
            ),
          ),
          _RoleCard(
            title: 'الإحصائيات',
            subtitle: 'لوحات عامة وشخصية',
            icon: Icons.insights,
            color: JadalColors.judgesGrey,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
