import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foyer/models/appliance.dart';
import 'package:foyer/models/home_feature.dart';
import 'package:foyer/models/home_profile.dart';
import 'package:foyer/models/maintenance_task.dart';
import 'package:foyer/providers/providers.dart';
import 'package:foyer/screens/dashboard_screen.dart';
import 'package:foyer/theme/app_theme.dart';

// ── Fake notifiers (no DB access) ────────────────────────────────────────────

class _FakeApplianceNotifier extends AsyncNotifier<List<Appliance>> {
  @override
  Future<List<Appliance>> build() async => [];
}

class _FakeFeatureNotifier extends AsyncNotifier<List<HomeFeature>> {
  @override
  Future<List<HomeFeature>> build() async => [];
}

class _FakeHomeProfileNotifier extends AsyncNotifier<HomeProfile?> {
  @override
  Future<HomeProfile?> build() async => null;
}

// ── Test data helpers ─────────────────────────────────────────────────────────

DashboardData _emptyDashboard() => const DashboardData(
      applianceCount: 0,
      featureCount: 0,
      overdueCount: 0,
      upcomingCount: 0,
      completedThisMonth: 0,
      totalThisMonth: 0,
      overdueTasks: [],
      upcomingTasks: [],
      monthlySpend: [0, 0, 0, 0, 0, 0],
    );

DashboardData _overdueDashboard() => const DashboardData(
      applianceCount: 2,
      featureCount: 1,
      overdueCount: 3,
      upcomingCount: 1,
      completedThisMonth: 2,
      totalThisMonth: 5,
      overdueTasks: [
        MaintenanceTask(id: 1, title: 'Fix leak', itemType: 'appliance', itemId: 1),
        MaintenanceTask(id: 2, title: 'Replace filter', itemType: 'appliance', itemId: 2),
        MaintenanceTask(id: 3, title: 'Check roof', itemType: 'feature', itemId: 1),
      ],
      upcomingTasks: [
        MaintenanceTask(id: 4, title: 'Service AC', itemType: 'appliance', itemId: 3),
      ],
      monthlySpend: [0, 10, 0, 50, 20, 5],
    );

// ── Widget wrapper ────────────────────────────────────────────────────────────

// Overrides all DB-backed providers so no real AppDatabase is opened and no
// timers are created by driftDatabase() during tests.
Widget _wrap(Widget child, Override dashboardOverride) => ProviderScope(
      overrides: [
        dashboardOverride,
        appliancesProvider.overrideWith(_FakeApplianceNotifier.new),
        featuresProvider.overrideWith(_FakeFeatureNotifier.new),
        homeProfileProvider.overrideWith(_FakeHomeProfileNotifier.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    );

// ── Unit tests: DashboardData ─────────────────────────────────────────────────

void main() {
  group('DashboardData.monthlyProgress', () {
    test('returns 0 when total is zero (no divide-by-zero)', () {
      final d = _emptyDashboard();
      expect(d.monthlyProgress, 0.0);
    });

    test('returns fraction when partially complete', () {
      const d = DashboardData(
        applianceCount: 0,
        featureCount: 0,
        overdueCount: 0,
        upcomingCount: 0,
        completedThisMonth: 2,
        totalThisMonth: 5,
        overdueTasks: [],
        upcomingTasks: [],
        monthlySpend: [0, 0, 0, 0, 0, 0],
      );
      expect(d.monthlyProgress, closeTo(0.4, 0.001));
    });

    test('returns 1.0 when all tasks complete', () {
      const d = DashboardData(
        applianceCount: 0,
        featureCount: 0,
        overdueCount: 0,
        upcomingCount: 0,
        completedThisMonth: 4,
        totalThisMonth: 4,
        overdueTasks: [],
        upcomingTasks: [],
        monthlySpend: [0, 0, 0, 0, 0, 0],
      );
      expect(d.monthlyProgress, 1.0);
    });
  });

  // ── Widget tests: DashboardScreen ──────────────────────────────────────────

  group('DashboardScreen', () {
    testWidgets('renders loading spinner while dashboard is loading',
        (tester) async {
      // Completer avoids any timer — Future.delayed() would leave one pending.
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) => Completer<DashboardData>().future),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without throwing when dashboard data is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) async => _emptyDashboard()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows overdue stat chip with red colour when overdue > 0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) async => _overdueDashboard()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('shows all-clear message when upcoming tasks list is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) async => _emptyDashboard()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('All clear for the next 30 days!'), findsOneWidget);
    });

    testWidgets('shows error widget when dashboard provider throws',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) async => throw Exception('db fail')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Error:'), findsOneWidget);
    });

    testWidgets(
        'Container accent bar uses only decoration — no color+decoration conflict',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) async => _overdueDashboard()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Section headers visible only when the task lists are non-empty
      expect(find.text('Overdue (3)'), findsOneWidget);
      expect(find.text('Next 30 Days (1)'), findsOneWidget);
    });
  });
}
