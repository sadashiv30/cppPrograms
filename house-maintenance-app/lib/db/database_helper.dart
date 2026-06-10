import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/appliance.dart';
import '../models/home_feature.dart';
import '../models/maintenance_task.dart';
import '../models/task_completion.dart';
import '../models/home_profile.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();
  static DatabaseHelper get instance => _instance ??= DatabaseHelper._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'house_maintenance_v2.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createV1(db);
    await _createV2(db);
    await _createV3(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createV2(db);
    if (oldVersion < 3) await _createV3(db);
  }

  Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE appliances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        model TEXT,
        serial_number TEXT,
        location TEXT,
        install_date TEXT,
        warranty_expiry TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE home_features (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        location TEXT,
        install_date TEXT,
        last_serviced TEXT,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE maintenance_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        frequency_days INTEGER DEFAULT 0,
        last_done TEXT,
        next_due TEXT,
        priority INTEGER DEFAULT 2,
        completed INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');
  }

  Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        completed_date TEXT NOT NULL,
        cost REAL DEFAULT 0.0,
        notes TEXT,
        FOREIGN KEY (task_id) REFERENCES maintenance_tasks(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createV3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS home_profile (
        id INTEGER PRIMARY KEY,
        address TEXT NOT NULL,
        city TEXT,
        state TEXT,
        zip TEXT,
        year_built INTEGER,
        bedrooms INTEGER,
        bathrooms REAL,
        sqft REAL,
        property_type TEXT,
        heating_type TEXT,
        cooling_type TEXT,
        roof_type TEXT,
        foundation_type TEXT,
        has_pool INTEGER,
        parking_type TEXT
      )
    ''');
  }

  // ── Appliances ──────────────────────────────────────────────────────────────

  Future<List<Appliance>> getAppliances() async {
    final db = await database;
    final rows = await db.query('appliances', orderBy: 'name ASC');
    return rows.map(Appliance.fromMap).toList();
  }

  Future<Appliance?> getAppliance(int id) async {
    final db = await database;
    final rows = await db.query('appliances', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Appliance.fromMap(rows.first);
  }

  Future<int> insertAppliance(Appliance a) async {
    final db = await database;
    return db.insert('appliances', a.toMap());
  }

  Future<void> updateAppliance(Appliance a) async {
    final db = await database;
    await db.update('appliances', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deleteAppliance(int id) async {
    final db = await database;
    await db.delete('appliances', where: 'id = ?', whereArgs: [id]);
  }

  // ── Home Features ───────────────────────────────────────────────────────────

  Future<List<HomeFeature>> getFeatures() async {
    final db = await database;
    final rows = await db.query('home_features', orderBy: 'category ASC, name ASC');
    return rows.map(HomeFeature.fromMap).toList();
  }

  Future<HomeFeature?> getFeature(int id) async {
    final db = await database;
    final rows = await db.query('home_features', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : HomeFeature.fromMap(rows.first);
  }

  Future<int> insertFeature(HomeFeature f) async {
    final db = await database;
    return db.insert('home_features', f.toMap());
  }

  Future<void> updateFeature(HomeFeature f) async {
    final db = await database;
    await db.update('home_features', f.toMap(), where: 'id = ?', whereArgs: [f.id]);
  }

  Future<void> deleteFeature(int id) async {
    final db = await database;
    await db.delete('home_features', where: 'id = ?', whereArgs: [id]);
  }

  // ── Maintenance Tasks ───────────────────────────────────────────────────────

  Future<List<MaintenanceTask>> getTasks() async {
    final db = await database;
    final rows = await db.query('maintenance_tasks', orderBy: 'next_due ASC, priority ASC');
    return rows.map(MaintenanceTask.fromMap).toList();
  }

  Future<List<MaintenanceTask>> getOverdueTasks() async {
    final db = await database;
    final today = _today();
    final rows = await db.query(
      'maintenance_tasks',
      where: "completed = 0 AND next_due != '' AND next_due < ?",
      whereArgs: [today],
      orderBy: 'priority ASC, next_due ASC',
    );
    return rows.map(MaintenanceTask.fromMap).toList();
  }

  Future<List<MaintenanceTask>> getUpcomingTasks(int days) async {
    final db = await database;
    final today = _today();
    final limit = DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);
    final rows = await db.query(
      'maintenance_tasks',
      where: "completed = 0 AND next_due != '' AND next_due >= ? AND next_due <= ?",
      whereArgs: [today, limit],
      orderBy: 'next_due ASC',
    );
    return rows.map(MaintenanceTask.fromMap).toList();
  }

  Future<int> insertTask(MaintenanceTask t) async {
    final db = await database;
    return db.insert('maintenance_tasks', t.toMap());
  }

  Future<void> updateTask(MaintenanceTask t) async {
    final db = await database;
    await db.update('maintenance_tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> completeTask(MaintenanceTask t, DateTime doneDate,
      {double cost = 0, String notes = ''}) async {
    final db = await database;
    final done = doneDate.toIso8601String().substring(0, 10);

    // Record in history
    await db.insert('task_completions', TaskCompletion(
      taskId: t.id!,
      completedDate: done,
      cost: cost,
      notes: notes,
    ).toMap());

    // Update task
    MaintenanceTask updated;
    if (t.frequencyDays > 0) {
      final nextDue = doneDate
          .add(Duration(days: t.frequencyDays))
          .toIso8601String()
          .substring(0, 10);
      updated = t.copyWith(lastDone: done, nextDue: nextDue, completed: false);
    } else {
      updated = t.copyWith(lastDone: done, completed: true);
    }
    await db.update('maintenance_tasks', updated.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('task_completions', where: 'task_id = ?', whereArgs: [id]);
    await db.delete('maintenance_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ── Task Completions (History) ──────────────────────────────────────────────

  Future<List<TaskCompletion>> getCompletionsForTask(int taskId) async {
    final db = await database;
    final rows = await db.query(
      'task_completions',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'completed_date DESC',
    );
    return rows.map(TaskCompletion.fromMap).toList();
  }

  Future<List<TaskCompletion>> getRecentCompletions({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'task_completions',
      orderBy: 'completed_date DESC',
      limit: limit,
    );
    return rows.map(TaskCompletion.fromMap).toList();
  }

  // ── Dashboard Stats ─────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final today = _today();
    final limit = DateTime.now().add(const Duration(days: 30))
        .toIso8601String().substring(0, 10);

    final results = await Future.wait([
      db.rawQuery('SELECT COUNT(*) as c FROM appliances'),
      db.rawQuery('SELECT COUNT(*) as c FROM home_features'),
      db.rawQuery(
          "SELECT COUNT(*) as c FROM maintenance_tasks WHERE completed=0 AND next_due!='' AND next_due<?",
          [today]),
      db.rawQuery(
          "SELECT COUNT(*) as c FROM maintenance_tasks WHERE completed=0 AND next_due!='' AND next_due>=? AND next_due<=?",
          [today, limit]),
    ]);

    return {
      'appliances': results[0].first['c'] as int,
      'features':   results[1].first['c'] as int,
      'overdue':    results[2].first['c'] as int,
      'upcoming':   results[3].first['c'] as int,
    };
  }

  Future<Map<String, int>> getMonthlyStats() async {
    final db = await database;
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10);
    final today = _today();

    final completed = await db.rawQuery(
      'SELECT COUNT(*) as c FROM task_completions WHERE completed_date >= ?',
      [firstOfMonth],
    );
    final total = await db.rawQuery(
      "SELECT COUNT(*) as c FROM maintenance_tasks WHERE (next_due >= ? AND next_due <= ?) OR completed=1",
      [firstOfMonth, today],
    );

    return {
      'completed': completed.first['c'] as int,
      'total': total.first['c'] as int,
    };
  }

  Future<List<double>> getMonthlySpend() async {
    final db = await database;
    final now = DateTime.now();
    final List<double> result = [];

    for (int i = 5; i >= 0; i--) {
      final dt = DateTime(now.year, now.month - i, 1);
      final from = DateTime(dt.year, dt.month, 1).toIso8601String().substring(0, 10);
      final to   = DateTime(dt.year, dt.month + 1, 0).toIso8601String().substring(0, 10);
      final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(cost),0) as s FROM task_completions WHERE completed_date >= ? AND completed_date <= ?',
        [from, to],
      );
      result.add((rows.first['s'] as num?)?.toDouble() ?? 0.0);
    }
    return result;
  }

  // ── Home Profile ────────────────────────────────────────────────────────────

  Future<HomeProfile?> getHomeProfile() async {
    final db = await database;
    final rows = await db.query('home_profile', limit: 1);
    return rows.isEmpty ? null : HomeProfile.fromMap(rows.first);
  }

  Future<void> saveHomeProfile(HomeProfile p) async {
    final db = await database;
    final existing = await db.query('home_profile', limit: 1);
    if (existing.isEmpty) {
      await db.insert('home_profile', p.copyWith(id: 1).toMap());
    } else {
      await db.update('home_profile', p.copyWith(id: 1).toMap(),
          where: 'id = ?', whereArgs: [1]);
    }
  }

  Future<void> deleteHomeProfile() async {
    final db = await database;
    await db.delete('home_profile');
  }

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);
}
