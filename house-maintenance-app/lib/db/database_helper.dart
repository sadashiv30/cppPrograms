import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/appliance.dart';
import '../models/home_feature.dart';
import '../models/maintenance_task.dart';

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
    final path = join(dbPath, 'house_maintenance.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
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

  // ── Appliances ──────────────────────────────────────────────

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

  // ── Home Features ────────────────────────────────────────────

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

  // ── Maintenance Tasks ────────────────────────────────────────

  Future<List<MaintenanceTask>> getTasks() async {
    final db = await database;
    final rows = await db.query('maintenance_tasks', orderBy: 'next_due ASC');
    return rows.map(MaintenanceTask.fromMap).toList();
  }

  Future<List<MaintenanceTask>> getOverdueTasks() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.query(
      'maintenance_tasks',
      where: 'completed = 0 AND next_due != "" AND next_due < ?',
      whereArgs: [today],
      orderBy: 'priority ASC, next_due ASC',
    );
    return rows.map(MaintenanceTask.fromMap).toList();
  }

  Future<List<MaintenanceTask>> getUpcomingTasks(int days) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final limit = DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);
    final rows = await db.query(
      'maintenance_tasks',
      where: 'completed = 0 AND next_due != "" AND next_due >= ? AND next_due <= ?',
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

  Future<void> completeTask(MaintenanceTask t, DateTime doneDate) async {
    final done = doneDate.toIso8601String().substring(0, 10);
    MaintenanceTask updated;
    if (t.frequencyDays > 0) {
      final nextDue = doneDate.add(Duration(days: t.frequencyDays))
          .toIso8601String().substring(0, 10);
      updated = t.copyWith(lastDone: done, nextDue: nextDue, completed: false);
    } else {
      updated = t.copyWith(lastDone: done, completed: true);
    }
    await updateTask(updated);
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('maintenance_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ── Dashboard stats ──────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final limit = DateTime.now().add(const Duration(days: 30))
        .toIso8601String().substring(0, 10);

    final counts = await Future.wait([
      db.rawQuery('SELECT COUNT(*) as c FROM appliances'),
      db.rawQuery('SELECT COUNT(*) as c FROM home_features'),
      db.rawQuery("SELECT COUNT(*) as c FROM maintenance_tasks WHERE completed = 0 AND next_due != '' AND next_due < ?", [today]),
      db.rawQuery("SELECT COUNT(*) as c FROM maintenance_tasks WHERE completed = 0 AND next_due != '' AND next_due >= ? AND next_due <= ?", [today, limit]),
    ]);

    return {
      'appliances': counts[0].first['c'] as int,
      'features': counts[1].first['c'] as int,
      'overdue': counts[2].first['c'] as int,
      'upcoming': counts[3].first['c'] as int,
    };
  }
}
