import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────

class Appliances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get brand => text().withDefault(const Constant(''))();
  TextColumn get model => text().withDefault(const Constant(''))();
  TextColumn get serialNumber =>
      text().named('serial_number').withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get installDate =>
      text().named('install_date').withDefault(const Constant(''))();
  TextColumn get warrantyExpiry =>
      text().named('warranty_expiry').withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class HomeFeatures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  TextColumn get name => text()();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get installDate =>
      text().named('install_date').withDefault(const Constant(''))();
  TextColumn get lastServiced =>
      text().named('last_serviced').withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class MaintenanceTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get itemType => text().named('item_type')();
  IntColumn get itemId => integer().named('item_id')();
  IntColumn get frequencyDays =>
      integer().named('frequency_days').withDefault(const Constant(0))();
  TextColumn get lastDone =>
      text().named('last_done').withDefault(const Constant(''))();
  TextColumn get nextDue =>
      text().named('next_due').withDefault(const Constant(''))();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  IntColumn get completed => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().named('task_id')
      .references(MaintenanceTasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get completedDate => text().named('completed_date')();
  RealColumn get cost => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
}

// Uses tableName override so SQL table is 'home_profile' (singular).
// Class is HomeProfiles (plural) to avoid conflict with the HomeProfile model.
class HomeProfiles extends Table {
  @override
  String get tableName => 'home_profile';

  IntColumn get id => integer()();
  TextColumn get address => text()();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get state => text().withDefault(const Constant(''))();
  TextColumn get zip => text().withDefault(const Constant(''))();
  IntColumn get yearBuilt => integer().named('year_built').nullable()();
  IntColumn get bedrooms => integer().nullable()();
  RealColumn get bathrooms => real().nullable()();
  RealColumn get sqft => real().nullable()();
  TextColumn get propertyType => text().named('property_type').nullable()();
  TextColumn get heatingType => text().named('heating_type').nullable()();
  TextColumn get coolingType => text().named('cooling_type').nullable()();
  TextColumn get roofType => text().named('roof_type').nullable()();
  TextColumn get foundationType =>
      text().named('foundation_type').nullable()();
  IntColumn get hasPool => integer().named('has_pool').nullable()();
  TextColumn get parkingType => text().named('parking_type').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Appliances,
  HomeFeatures,
  MaintenanceTasks,
  TaskCompletions,
  HomeProfiles,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );

  static QueryExecutor _openConnection() => driftDatabase(name: 'foyer');
}
