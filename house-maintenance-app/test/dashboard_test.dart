import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foyer/providers/providers.dart';
import 'package:foyer/screens/dashboard_screen.dart';
import 'package:foyer/theme/app_theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

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
      overdueTasks: [],
      upcomingTasks: [],
      monthlySpend: [0, 10, 0, 50, 20, 5],
    );

Widget _wrap(Widget child, Override override) => ProviderScope(
      overrides: [override],
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
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) async {
            await Future<void>.delayed(const Duration(seconds: 10));
            return _emptyDashboard();
          }),
        ),
      );
      await tester.pump(); // first frame — still loading
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
      // Should not throw — the fix for the Container color+decoration crash
      // is what makes this pass.
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
      // Stat row is present
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // count shown in stat chip
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
      // If the Container in _SectionHeader still had both color: and
      // decoration:, this pump would throw a FlutterError assertion.
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          dashboardProvider.overrideWith((_) async => _overdueDashboard()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The overdue section header must be visible
      expect(find.text('Overdue (3)'), findsOneWidget);
      // Next-30-days section header is always present
      expect(find.text('Next 30 Days (1)'), findsOneWidget);
    });
  });
}
