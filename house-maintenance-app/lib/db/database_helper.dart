import 'package:drift/drift.dart';
import 'app_database.dart' show AppDatabase;
import '../models/appliance.dart';
import '../models/home_feature.dart';
import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/home_profile.dart' as model;

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static AppDatabase? _appDb;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  AppDatabase get _db => _appDb ??= AppDatabase();

  // ── Appliances ──────────────────────────────────────────────────────────────

  Future<List<Appliance>> getAppliances() async {
    final rows = await _db
        .customSelect('SELECT * FROM appliances ORDER BY name ASC')
        .get();
    return rows.map((r) => Appliance.fromMap(r.data)).toList();
  }

  Future<Appliance?> getAppliance(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM appliances WHERE id = ?',
      variables: [Variable<int>(id)],
    ).get();
    return rows.isEmpty ? null : Appliance.fromMap(rows.first.data);
  }

  Future<int> insertAppliance(Appliance a) => _db.customInsert(
        'INSERT INTO appliances '
        '(name, brand, model, serial_number, location, install_date, warranty_expiry, notes) '
        'VALUES (?,?,?,?,?,?,?,?)',
        variables: [
          Variable<String>(a.name),
          Variable<String>(a.brand),
          Variable<String>(a.model),
          Variable<String>(a.serialNumber),
          Variable<String>(a.location),
          Variable<String>(a.installDate),
          Variable<String>(a.warrantyExpiry),
          Variable<String>(a.notes),
        ],
      );

  Future<void> updateAppliance(Appliance a) => _db.customUpdate(
        'UPDATE appliances SET name=?, brand=?, model=?, serial_number=?, '
        'location=?, install_date=?, warranty_expiry=?, notes=? WHERE id=?',
        variables: [
          Variable<String>(a.name),
          Variable<String>(a.brand),
          Variable<String>(a.model),
          Variable<String>(a.serialNumber),
          Variable<String>(a.location),
          Variable<String>(a.installDate),
          Variable<String>(a.warrantyExpiry),
          Variable<String>(a.notes),
          Variable<int>(a.id!),
        ],
      );

  Future<void> deleteAppliance(int id) => _db.customUpdate(
        'DELETE FROM appliances WHERE id=?',
        variables: [Variable<int>(id)],
      );

  // ── Home Features ───────────────────────────────────────────────────────────

  Future<List<HomeFeature>> getFeatures() async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM home_features ORDER BY category ASC, name ASC',
        )
        .get();
    return rows.map((r) => HomeFeature.fromMap(r.data)).toList();
  }

  Future<HomeFeature?> getFeature(int id) async {
    final rows = await _db.customSelect(
      'SELECT * FROM home_features WHERE id=?',
      variables: [Variable<int>(id)],
    ).get();
    return rows.isEmpty ? null : HomeFeature.fromMap(rows.first.data);
  }

  Future<int> insertFeature(HomeFeature f) => _db.customInsert(
        'INSERT INTO home_features '
        '(category, name, location, install_date, last_serviced, notes) '
        'VALUES (?,?,?,?,?,?)',
        variables: [
          Variable<String>(f.category),
          Variable<String>(f.name),
          Variable<String>(f.location),
          Variable<String>(f.installDate),
          Variable<String>(f.lastServiced),
          Variable<String>(f.notes),
        ],
      );

  Future<void> updateFeature(HomeFeature f) => _db.customUpdate(
        'UPDATE home_features SET category=?, name=?, location=?, '
        'install_date=?, last_serviced=?, notes=? WHERE id=?',
        variables: [
          Variable<String>(f.category),
          Variable<String>(f.name),
          Variable<String>(f.location),
          Variable<String>(f.installDate),
          Variable<String>(f.lastServiced),
          Variable<String>(f.notes),
          Variable<int>(f.id!),
        ],
      );

  Future<void> deleteFeature(int id) => _db.customUpdate(
        'DELETE FROM home_features WHERE id=?',
        variables: [Variable<int>(id)],
      );

  // ── Maintenance Tasks ───────────────────────────────────────────────────────

  Future<List<MaintenanceTask>> getTasks() async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM maintenance_tasks ORDER BY next_due ASC, priority ASC',
        )
        .get();
    return rows.map((r) => MaintenanceTask.fromMap(r.data)).toList();
  }

  Future<List<MaintenanceTask>> getOverdueTasks() async {
    final rows = await _db.customSelect(
      "SELECT * FROM maintenance_tasks "
      "WHERE completed=0 AND next_due!='' AND next_due<? "
      "ORDER BY priority ASC, next_due ASC",
      variables: [Variable<String>(_today())],
    ).get();
    return rows.map((r) => MaintenanceTask.fromMap(r.data)).toList();
  }

  Future<List<MaintenanceTask>> getUpcomingTasks(int days) async {
    final limit = DateTime.now()
        .add(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    final rows = await _db.customSelect(
      "SELECT * FROM maintenance_tasks "
      "WHERE completed=0 AND next_due!='' AND next_due>=? AND next_due<=? "
      "ORDER BY next_due ASC",
      variables: [Variable<String>(_today()), Variable<String>(limit)],
    ).get();
    return rows.map((r) => MaintenanceTask.fromMap(r.data)).toList();
  }

  Future<int> insertTask(MaintenanceTask t) => _db.customInsert(
        'INSERT INTO maintenance_tasks '
        '(title, item_type, item_id, frequency_days, last_done, next_due, priority, completed, notes) '
        'VALUES (?,?,?,?,?,?,?,?,?)',
        variables: [
          Variable<String>(t.title),
          Variable<String>(t.itemType),
          Variable<int>(t.itemId),
          Variable<int>(t.frequencyDays),
          Variable<String>(t.lastDone),
          Variable<String>(t.nextDue),
          Variable<int>(t.priority),
          Variable<int>(t.completed ? 1 : 0),
          Variable<String>(t.notes),
        ],
      );

  Future<void> updateTask(MaintenanceTask t) => _db.customUpdate(
        'UPDATE maintenance_tasks SET title=?, item_type=?, item_id=?, '
        'frequency_days=?, last_done=?, next_due=?, priority=?, completed=?, notes=? '
        'WHERE id=?',
        variables: [
          Variable<String>(t.title),
          Variable<String>(t.itemType),
          Variable<int>(t.itemId),
          Variable<int>(t.frequencyDays),
          Variable<String>(t.lastDone),
          Variable<String>(t.nextDue),
          Variable<int>(t.priority),
          Variable<int>(t.completed ? 1 : 0),
          Variable<String>(t.notes),
          Variable<int>(t.id!),
        ],
      );

  Future<void> completeTask(
    MaintenanceTask t,
    DateTime doneDate, {
    double cost = 0,
    String notes = '',
  }) async {
    final done = doneDate.toIso8601String().substring(0, 10);
    await _db.customInsert(
      'INSERT INTO task_completions (task_id, completed_date, cost, notes) VALUES (?,?,?,?)',
      variables: [
        Variable<int>(t.id!),
        Variable<String>(done),
        Variable<double>(cost),
        Variable<String>(notes),
      ],
    );

    final MaintenanceTask updated;
    if (t.frequencyDays > 0) {
      final nextDue = doneDate
          .add(Duration(days: t.frequencyDays))
          .toIso8601String()
          .substring(0, 10);
      updated = t.copyWith(lastDone: done, nextDue: nextDue, completed: false);
    } else {
      updated = t.copyWith(lastDone: done, completed: true);
    }
    await updateTask(updated);
  }

  Future<void> deleteTask(int id) async {
    await _db.customUpdate(
      'DELETE FROM task_completions WHERE task_id=?',
      variables: [Variable<int>(id)],
    );
    await _db.customUpdate(
      'DELETE FROM maintenance_tasks WHERE id=?',
      variables: [Variable<int>(id)],
    );
  }

  // ── Task Completions (history) ──────────────────────────────────────────────

  Future<List<TaskCompletion>> getCompletionsForTask(int taskId) async {
    final rows = await _db.customSelect(
      'SELECT * FROM task_completions WHERE task_id=? ORDER BY completed_date DESC',
      variables: [Variable<int>(taskId)],
    ).get();
    return rows.map((r) => TaskCompletion.fromMap(r.data)).toList();
  }

  Future<List<TaskCompletion>> getRecentCompletions({int limit = 20}) async {
    final rows = await _db.customSelect(
      'SELECT * FROM task_completions ORDER BY completed_date DESC LIMIT ?',
      variables: [Variable<int>(limit)],
    ).get();
    return rows.map((r) => TaskCompletion.fromMap(r.data)).toList();
  }

  // ── Dashboard Stats ─────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final today = _today();
    final limit = DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String()
        .substring(0, 10);

    Future<int> count(String sql, [List<Variable> vars = const []]) async {
      final r = await _db.customSelect(sql, variables: vars).getSingle();
      return r.data['c'] as int;
    }

    final results = await Future.wait([
      count('SELECT COUNT(*) as c FROM appliances'),
      count('SELECT COUNT(*) as c FROM home_features'),
      count(
        "SELECT COUNT(*) as c FROM maintenance_tasks "
        "WHERE completed=0 AND next_due!='' AND next_due<?",
        [Variable<String>(today)],
      ),
      count(
        "SELECT COUNT(*) as c FROM maintenance_tasks "
        "WHERE completed=0 AND next_due!='' AND next_due>=? AND next_due<=?",
        [Variable<String>(today), Variable<String>(limit)],
      ),
    ]);

    return {
      'appliances': results[0],
      'features':   results[1],
      'overdue':    results[2],
      'upcoming':   results[3],
    };
  }

  Future<Map<String, int>> getMonthlyStats() async {
    final now   = DateTime.now();
    final first = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final last  = DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);

    final comp = await _db.customSelect(
      'SELECT COUNT(*) as c FROM task_completions '
      'WHERE completed_date>=? AND completed_date<=?',
      variables: [Variable<String>(first), Variable<String>(last)],
    ).getSingle();

    final total = await _db.customSelect(
      '''SELECT COUNT(*) as c FROM (
           SELECT task_id as id FROM task_completions
           WHERE completed_date>=? AND completed_date<=?
           UNION
           SELECT id FROM maintenance_tasks
           WHERE next_due>=? AND next_due<=? AND completed=0
         )''',
      variables: [
        Variable<String>(first),
        Variable<String>(last),
        Variable<String>(first),
        Variable<String>(last),
      ],
    ).getSingle();

    return {
      'completed': comp.data['c'] as int,
      'total':     total.data['c'] as int,
    };
  }

  Future<List<double>> getMonthlySpend() async {
    final now  = DateTime.now();
    final from = DateTime(now.year, now.month - 5, 1).toIso8601String().substring(0, 10);

    final rows = await _db.customSelect(
      "SELECT strftime('%Y-%m', completed_date) as month, "
      "COALESCE(SUM(cost), 0) as s "
      "FROM task_completions WHERE completed_date>=? "
      "GROUP BY month ORDER BY month ASC",
      variables: [Variable<String>(from)],
    ).get();

    final byMonth = <String, double>{
      for (final r in rows)
        r.data['month'] as String: (r.data['s'] as num).toDouble(),
    };

    return List.generate(6, (i) {
      final dt  = DateTime(now.year, now.month - 5 + i, 1);
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      return byMonth[key] ?? 0.0;
    });
  }

  // ── Home Profile ────────────────────────────────────────────────────────────

  Future<model.HomeProfile?> getHomeProfile() async {
    final rows =
        await _db.customSelect('SELECT * FROM home_profile LIMIT 1').get();
    return rows.isEmpty ? null : model.HomeProfile.fromMap(rows.first.data);
  }

  Future<void> saveHomeProfile(model.HomeProfile p) async {
    final existing =
        await _db.customSelect('SELECT id FROM home_profile LIMIT 1').get();
    final hasPool = p.hasPool == null ? null : (p.hasPool! ? 1 : 0);
    if (existing.isEmpty) {
      await _db.customInsert(
        'INSERT INTO home_profile '
        '(id, address, city, state, zip, year_built, bedrooms, bathrooms, sqft, '
        'property_type, heating_type, cooling_type, roof_type, foundation_type, '
        'has_pool, parking_type) VALUES (1,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
        variables: [
          Variable<String>(p.address),
          Variable<String>(p.city),
          Variable<String>(p.state),
          Variable<String>(p.zip),
          Variable<int>(p.yearBuilt),
          Variable<int>(p.bedrooms),
          Variable<double>(p.bathrooms),
          Variable<double>(p.sqft),
          Variable<String>(p.propertyType),
          Variable<String>(p.heatingType),
          Variable<String>(p.coolingType),
          Variable<String>(p.roofType),
          Variable<String>(p.foundationType),
          Variable<int>(hasPool),
          Variable<String>(p.parkingType),
        ],
      );
    } else {
      await _db.customUpdate(
        'UPDATE home_profile SET address=?, city=?, state=?, zip=?, '
        'year_built=?, bedrooms=?, bathrooms=?, sqft=?, property_type=?, '
        'heating_type=?, cooling_type=?, roof_type=?, foundation_type=?, '
        'has_pool=?, parking_type=? WHERE id=1',
        variables: [
          Variable<String>(p.address),
          Variable<String>(p.city),
          Variable<String>(p.state),
          Variable<String>(p.zip),
          Variable<int>(p.yearBuilt),
          Variable<int>(p.bedrooms),
          Variable<double>(p.bathrooms),
          Variable<double>(p.sqft),
          Variable<String>(p.propertyType),
          Variable<String>(p.heatingType),
          Variable<String>(p.coolingType),
          Variable<String>(p.roofType),
          Variable<String>(p.foundationType),
          Variable<int>(hasPool),
          Variable<String>(p.parkingType),
        ],
      );
    }
  }

  Future<void> deleteHomeProfile() =>
      _db.customUpdate('DELETE FROM home_profile');

  // ── Clear All Data ──────────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    await _db.customUpdate('DELETE FROM task_completions');
    await _db.customUpdate('DELETE FROM maintenance_tasks');
    await _db.customUpdate('DELETE FROM home_features');
    await _db.customUpdate('DELETE FROM appliances');
    await _db.customUpdate('DELETE FROM home_profile');
  }

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);
}
