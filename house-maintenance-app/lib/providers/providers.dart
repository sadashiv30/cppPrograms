import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/appliance.dart';
import '../models/home_feature.dart';
import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/home_profile.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (_) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final idx = p.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[idx];
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final p = await SharedPreferences.getInstance();
    await p.setInt('theme_mode', mode.index);
  }
}

// ── Settings ──────────────────────────────────────────────────────────────────

final notificationsEnabledProvider = StateNotifierProvider<BoolPref, bool>(
  (_) => BoolPref('notifications_enabled', defaultValue: true),
);

class BoolPref extends StateNotifier<bool> {
  final String _key;
  BoolPref(this._key, {required bool defaultValue}) : super(defaultValue) {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getBool(_key) ?? state;
  }
  Future<void> toggle() async {
    state = !state;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, state);
  }
}

// ── API Key (Rentcast) ────────────────────────────────────────────────────────

final rentcastApiKeyProvider = StateNotifierProvider<StringPref, String>(
  (_) => StringPref('rentcast_api_key'),
);

class StringPref extends StateNotifier<String> {
  final String _key;
  StringPref(this._key) : super('') {
    _load();
  }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getString(_key) ?? '';
  }
  Future<void> set(String value) async {
    state = value;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, value);
  }
}

// ── Home Profile ──────────────────────────────────────────────────────────────

final homeProfileProvider =
    AsyncNotifierProvider<HomeProfileNotifier, HomeProfile?>(HomeProfileNotifier.new);

class HomeProfileNotifier extends AsyncNotifier<HomeProfile?> {
  @override
  Future<HomeProfile?> build() => DatabaseHelper.instance.getHomeProfile();

  Future<void> save(HomeProfile p) async {
    await DatabaseHelper.instance.saveHomeProfile(p);
    ref.invalidateSelf();
  }

  Future<void> delete() async {
    await DatabaseHelper.instance.deleteHomeProfile();
    ref.invalidateSelf();
  }
}

// ── Appliances ────────────────────────────────────────────────────────────────

final appliancesProvider =
    AsyncNotifierProvider<ApplianceNotifier, List<Appliance>>(ApplianceNotifier.new);

class ApplianceNotifier extends AsyncNotifier<List<Appliance>> {
  @override
  Future<List<Appliance>> build() => DatabaseHelper.instance.getAppliances();

  Future<void> add(Appliance a) async {
    await DatabaseHelper.instance.insertAppliance(a);
    ref.invalidateSelf();
  }

  Future<void> update(Appliance a) async {
    await DatabaseHelper.instance.updateAppliance(a);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deleteAppliance(id);
    ref.invalidateSelf();
  }
}

// ── Home Features ─────────────────────────────────────────────────────────────

final featuresProvider =
    AsyncNotifierProvider<FeatureNotifier, List<HomeFeature>>(FeatureNotifier.new);

class FeatureNotifier extends AsyncNotifier<List<HomeFeature>> {
  @override
  Future<List<HomeFeature>> build() => DatabaseHelper.instance.getFeatures();

  Future<void> add(HomeFeature f) async {
    await DatabaseHelper.instance.insertFeature(f);
    ref.invalidateSelf();
  }

  Future<void> update(HomeFeature f) async {
    await DatabaseHelper.instance.updateFeature(f);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deleteFeature(id);
    ref.invalidateSelf();
  }
}

// ── Tasks ─────────────────────────────────────────────────────────────────────

final tasksProvider =
    AsyncNotifierProvider<TaskNotifier, List<MaintenanceTask>>(TaskNotifier.new);

class TaskNotifier extends AsyncNotifier<List<MaintenanceTask>> {
  @override
  Future<List<MaintenanceTask>> build() => DatabaseHelper.instance.getTasks();

  Future<void> add(MaintenanceTask t) async {
    await DatabaseHelper.instance.insertTask(t);
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider);
  }

  Future<void> update(MaintenanceTask t) async {
    await DatabaseHelper.instance.updateTask(t);
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider);
  }

  Future<void> complete(MaintenanceTask t, DateTime date, {double cost = 0, String notes = ''}) async {
    await DatabaseHelper.instance.completeTask(t, date, cost: cost, notes: notes);
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider);
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    ref.invalidateSelf();
    ref.invalidate(dashboardProvider);
  }
}

// ── Completions (history) ─────────────────────────────────────────────────────

final completionsProvider =
    FutureProvider.family<List<TaskCompletion>, int>((ref, taskId) =>
        DatabaseHelper.instance.getCompletionsForTask(taskId));

// ── Dashboard ─────────────────────────────────────────────────────────────────

class DashboardData {
  final int applianceCount;
  final int featureCount;
  final int overdueCount;
  final int upcomingCount;
  final int completedThisMonth;
  final int totalThisMonth;
  final List<MaintenanceTask> overdueTasks;
  final List<MaintenanceTask> upcomingTasks;
  final List<double> monthlySpend; // last 6 months

  const DashboardData({
    required this.applianceCount,
    required this.featureCount,
    required this.overdueCount,
    required this.upcomingCount,
    required this.completedThisMonth,
    required this.totalThisMonth,
    required this.overdueTasks,
    required this.upcomingTasks,
    required this.monthlySpend,
  });

  double get monthlyProgress =>
      totalThisMonth == 0 ? 0 : completedThisMonth / totalThisMonth;
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final db = DatabaseHelper.instance;
  final results = await Future.wait([
    db.getStats(),
    db.getOverdueTasks(),
    db.getUpcomingTasks(30),
    db.getMonthlyStats(),
    db.getMonthlySpend(),
  ]);

  final stats        = results[0] as Map<String, int>;
  final overdue      = results[1] as List<MaintenanceTask>;
  final upcoming     = results[2] as List<MaintenanceTask>;
  final monthly      = results[3] as Map<String, int>;
  final spend        = results[4] as List<double>;

  return DashboardData(
    applianceCount: stats['appliances'] ?? 0,
    featureCount: stats['features'] ?? 0,
    overdueCount: stats['overdue'] ?? 0,
    upcomingCount: stats['upcoming'] ?? 0,
    completedThisMonth: monthly['completed'] ?? 0,
    totalThisMonth: monthly['total'] ?? 0,
    overdueTasks: overdue,
    upcomingTasks: upcoming,
    monthlySpend: spend,
  );
});
