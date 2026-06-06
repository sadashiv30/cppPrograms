import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/maintenance_task.dart';
import '../models/appliance.dart';
import '../models/home_feature.dart';
import 'tasks_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper.instance;
  Map<String, int> _stats = {};
  List<MaintenanceTask> _overdue = [];
  List<MaintenanceTask> _upcoming = [];
  Map<int, String> _applianceNames = {};
  Map<int, String> _featureNames = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _db.getStats(),
      _db.getOverdueTasks(),
      _db.getUpcomingTasks(30),
      _db.getAppliances(),
      _db.getFeatures(),
    ]);
    _stats = results[0] as Map<String, int>;
    _overdue = results[1] as List<MaintenanceTask>;
    _upcoming = results[2] as List<MaintenanceTask>;
    final appliances = results[3] as List<Appliance>;
    final features = results[4] as List<HomeFeature>;
    _applianceNames = {for (var a in appliances) a.id!: '${a.name} (${a.brand})'.trim()};
    _featureNames = {for (var f in features) f.id!: '${f.name} [${f.category}]'};
    setState(() => _loading = false);
  }

  String _itemName(MaintenanceTask t) {
    if (t.itemType == 'appliance') return _applianceNames[t.itemId] ?? 'Unknown';
    return _featureNames[t.itemId] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                Text(DateFormat('EEEE, MMMM d y').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant)),
                const SizedBox(height: 20),
                _statsRow(cs),
                const SizedBox(height: 24),
                _sectionHeader(context, 'Overdue', _overdue.length, Colors.red),
                if (_overdue.isEmpty)
                  _emptyCard('No overdue tasks', Icons.check_circle_outline)
                else
                  ..._overdue.map((t) => _taskCard(context, t, overdue: true)),
                const SizedBox(height: 16),
                _sectionHeader(context, 'Next 30 Days', _upcoming.length, cs.primary),
                if (_upcoming.isEmpty)
                  _emptyCard('Nothing due in the next 30 days', Icons.calendar_today_outlined)
                else
                  ..._upcoming.map((t) => _taskCard(context, t)),
              ],
            ),
    );
  }

  Widget _statsRow(ColorScheme cs) {
    return Row(children: [
      _statCard('Appliances', _stats['appliances'] ?? 0, Icons.kitchen, cs.primaryContainer, cs.onPrimaryContainer),
      const SizedBox(width: 8),
      _statCard('Features', _stats['features'] ?? 0, Icons.home_repair_service, cs.secondaryContainer, cs.onSecondaryContainer),
      const SizedBox(width: 8),
      _statCard('Overdue', _stats['overdue'] ?? 0, Icons.warning_amber, Colors.red.shade100, Colors.red.shade800),
    ]);
  }

  Widget _statCard(String label, int count, IconData icon, Color bg, Color fg) {
    return Expanded(
      child: Card(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: fg, size: 28),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg)),
            Text(label, style: TextStyle(fontSize: 11, color: fg)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(width: 4, height: 20, color: color,
            margin: const EdgeInsets.only(right: 8)),
        Text('$title ($count)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _emptyCard(String msg, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _taskCard(BuildContext context, MaintenanceTask t, {bool overdue = false}) {
    final priorityColor = switch (t.priority) {
      1 => Colors.red,
      3 => Colors.green,
      _ => Colors.orange,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.15),
          child: Icon(Icons.build_circle, color: priorityColor, size: 20),
        ),
        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(_itemName(t)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(t.nextDue,
                style: TextStyle(
                    color: overdue ? Colors.red : null,
                    fontWeight: overdue ? FontWeight.bold : null,
                    fontSize: 12)),
            Text(t.priorityLabel,
                style: TextStyle(color: priorityColor, fontSize: 11)),
          ],
        ),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => TasksScreen(highlightId: t.id)));
        },
      ),
    );
  }
}
