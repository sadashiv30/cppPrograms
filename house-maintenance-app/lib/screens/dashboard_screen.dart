import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/appliance.dart';
import '../models/home_feature.dart';
import '../models/maintenance_task.dart';
import '../widgets/task_tile.dart';
import '../models/home_profile.dart';
import 'property_setup_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _itemName(
    MaintenanceTask t,
    List<Appliance> appliances,
    List<HomeFeature> features,
  ) {
    if (t.itemType == 'appliance') {
      final a = appliances.where((a) => a.id == t.itemId).firstOrNull;
      return a != null ? '${a.name} · ${a.brand}'.trim() : 'Unknown';
    }
    final f = features.where((f) => f.id == t.itemId).firstOrNull;
    return f != null ? '${f.name} · ${f.category}' : 'Unknown';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync   = ref.watch(dashboardProvider);
    final appliances  = ref.watch(appliancesProvider).value ?? [];
    final features    = ref.watch(featuresProvider).value ?? [];
    final homeProfile = ref.watch(homeProfileProvider).value;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardProvider),
      child: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting header
                    _GreetingCard(
                      greeting: _greeting(),
                      overdueCount: d.overdueCount,
                      upcomingCount: d.upcomingCount,
                      profile: homeProfile,
                    ),
                    const SizedBox(height: 20),

                    // Stat chips row
                    Row(children: [
                      _StatChip(
                        label: 'Appliances',
                        value: d.applianceCount,
                        icon: Icons.kitchen_outlined,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Features',
                        value: d.featureCount,
                        icon: Icons.home_repair_service_outlined,
                        color: const Color(0xFF3949AB),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Overdue',
                        value: d.overdueCount,
                        icon: Icons.warning_amber_outlined,
                        color: d.overdueCount > 0 ? AppTheme.overdueColor : AppTheme.safeColor,
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Monthly progress card
                    _MonthlyProgressCard(
                      completed: d.completedThisMonth,
                      total: d.totalThisMonth,
                      progress: d.monthlyProgress,
                    ),
                    const SizedBox(height: 16),

                    // Spend chart
                    if (d.monthlySpend.any((s) => s > 0))
                      _SpendChart(monthlySpend: d.monthlySpend),

                    // Overdue
                    if (d.overdueTasks.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionHeader(
                        title: 'Overdue',
                        count: d.overdueTasks.length,
                        color: AppTheme.overdueColor,
                      ),
                      const SizedBox(height: 8),
                      ...d.overdueTasks.map((t) => TaskTile(
                            task: t,
                            itemName: _itemName(t, appliances, features),
                          )),
                    ],

                    // Upcoming
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Next 30 Days',
                      count: d.upcomingTasks.length,
                      color: AppTheme.upcomingColor,
                    ),
                    const SizedBox(height: 8),
                    if (d.upcomingTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          Icon(Icons.check_circle_outline,
                              color: AppTheme.safeColor, size: 18),
                          const SizedBox(width: 8),
                          Text('All clear for the next 30 days!',
                              style: TextStyle(color: AppTheme.safeColor)),
                        ]),
                      )
                    else
                      ...d.upcomingTasks.map((t) => TaskTile(
                            task: t,
                            itemName: _itemName(t, appliances, features),
                          )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Greeting card ─────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final int overdueCount;
  final int upcomingCount;
  final HomeProfile? profile;

  const _GreetingCard({
    required this.greeting,
    required this.overdueCount,
    required this.upcomingCount,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting,
              style: TextStyle(
                  fontSize: 14, color: cs.onPrimary.withOpacity(0.85))),
          Text('Your Home',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimary)),
          const SizedBox(height: 4),
          Text(today,
              style:
                  TextStyle(fontSize: 13, color: cs.onPrimary.withOpacity(0.7))),
          if (profile != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  size: 12, color: cs.onPrimary.withOpacity(0.7)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  profile!.address,
                  style: TextStyle(fontSize: 12, color: cs.onPrimary.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile!.bedrooms != null) ...[
                const SizedBox(width: 8),
                Text('${profile!.bedrooms} bd',
                    style: TextStyle(fontSize: 12, color: cs.onPrimary.withOpacity(0.7))),
              ],
              if (profile!.sqft != null) ...[
                const SizedBox(width: 8),
                Text('${profile!.sqft!.toStringAsFixed(0)} sqft',
                    style: TextStyle(fontSize: 12, color: cs.onPrimary.withOpacity(0.7))),
              ],
            ]),
          ],
          if (overdueCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$overdueCount task${overdueCount > 1 ? 's' : ''} need attention',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text('$value',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Monthly progress card ─────────────────────────────────────────────────────

class _MonthlyProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _MonthlyProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final month = DateFormat('MMMM').format(DateTime.now());
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.bar_chart_outlined, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('$month Progress',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('$completed / $total tasks',
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                  progress >= 1.0 ? AppTheme.safeColor : cs.primary),
            ),
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.celebration, color: AppTheme.safeColor, size: 14),
              const SizedBox(width: 4),
              Text('All tasks done!',
                  style: TextStyle(fontSize: 12, color: AppTheme.safeColor)),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── Spend chart ───────────────────────────────────────────────────────────────

class _SpendChart extends StatelessWidget {
  final List<double> monthlySpend;

  const _SpendChart({required this.monthlySpend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final maxY = monthlySpend.reduce((a, b) => a > b ? a : b) * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.attach_money, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('Maintenance Spend',
                style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 4),
          Text('Last 6 months', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                maxY: maxY < 1 ? 100 : maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final month = DateTime(now.year, now.month - (5 - val.toInt()), 1);
                        return Text(DateFormat('MMM').format(month),
                            style: Theme.of(context).textTheme.labelSmall);
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                barGroups: List.generate(
                  monthlySpend.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlySpend[i],
                        color: i == monthlySpend.length - 1
                            ? cs.primary
                            : cs.primary.withOpacity(0.4),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 3, height: 18,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text('$title ($count)',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}
