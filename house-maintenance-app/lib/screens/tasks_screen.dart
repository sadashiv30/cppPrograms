import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/maintenance_task.dart';
import '../models/appliance.dart';
import '../models/home_feature.dart';

enum _Filter { all, overdue, upcoming }

class TasksScreen extends StatefulWidget {
  final int? highlightId;
  const TasksScreen({super.key, this.highlightId});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _db = DatabaseHelper.instance;
  List<MaintenanceTask> _tasks = [];
  List<Appliance> _appliances = [];
  List<HomeFeature> _features = [];
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _db.getTasks(),
      _db.getAppliances(),
      _db.getFeatures(),
    ]);
    setState(() {
      _tasks = results[0] as List<MaintenanceTask>;
      _appliances = results[1] as List<Appliance>;
      _features = results[2] as List<HomeFeature>;
    });
  }

  List<MaintenanceTask> get _filtered {
    return switch (_filter) {
      _Filter.overdue  => _tasks.where((t) => t.isOverdue).toList(),
      _Filter.upcoming => _tasks.where((t) => t.isDueSoon(30)).toList(),
      _Filter.all      => _tasks,
    };
  }

  String _itemName(MaintenanceTask t) {
    if (t.itemType == 'appliance') {
      final a = _appliances.where((a) => a.id == t.itemId).firstOrNull;
      return a != null ? '${a.name} (${a.brand})'.trim() : 'Unknown';
    }
    final f = _features.where((f) => f.id == t.itemId).firstOrNull;
    return f != null ? '${f.name} [${f.category}]' : 'Unknown';
  }

  Future<void> _complete(MaintenanceTask t) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Date completed',
    );
    if (picked != null) {
      await _db.completeTask(t, picked);
      _load();
    }
  }

  Future<void> _delete(MaintenanceTask t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${t.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteTask(t.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: filtered.isEmpty
                ? _empty()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _taskCard(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_appliances.isEmpty && _features.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add an appliance or home feature first.')),
            );
            return;
          }
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => TaskFormScreen(
              appliances: _appliances,
              features: _features,
            ),
          ));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: SegmentedButton<_Filter>(
        segments: const [
          ButtonSegment(value: _Filter.all, label: Text('All')),
          ButtonSegment(value: _Filter.overdue, label: Text('Overdue')),
          ButtonSegment(value: _Filter.upcoming, label: Text('30 Days')),
        ],
        selected: {_filter},
        onSelectionChanged: (s) => setState(() => _filter = s.first),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.task_alt, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          _filter == _Filter.overdue
              ? 'No overdue tasks!'
              : _filter == _Filter.upcoming
                  ? 'Nothing due in 30 days'
                  : 'No tasks yet',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ]),
    );
  }

  Widget _taskCard(MaintenanceTask t) {
    final isOverdue = t.isOverdue;
    final highlight = t.id == widget.highlightId;
    final priorityColor = switch (t.priority) {
      1 => Colors.red,
      3 => Colors.green,
      _ => Colors.orange,
    };
    final freqLabel = t.frequencyDays > 0 ? 'Every ${t.frequencyDays}d' : 'One-time';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor.withOpacity(0.15),
          child: Icon(Icons.build, color: priorityColor, size: 18),
        ),
        title: Row(children: [
          Expanded(child: Text(t.title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: t.completed ? TextDecoration.lineThrough : null))),
          if (isOverdue)
            const Chip(
              label: Text('OVERDUE', style: TextStyle(fontSize: 10)),
              backgroundColor: Colors.red,
              padding: EdgeInsets.zero,
            ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_itemName(t), style: const TextStyle(fontSize: 12)),
            Row(children: [
              Text('Due: ${t.nextDue.isEmpty ? "—" : t.nextDue}',
                  style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : null,
                      fontWeight: isOverdue ? FontWeight.bold : null)),
              const SizedBox(width: 8),
              Text(freqLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Text(t.priorityLabel, style: TextStyle(fontSize: 12, color: priorityColor)),
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'complete') await _complete(t);
            else if (v == 'edit') {
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => TaskFormScreen(
                    task: t, appliances: _appliances, features: _features)));
              _load();
            } else if (v == 'delete') await _delete(t);
          },
          itemBuilder: (_) => [
            if (!t.completed)
              const PopupMenuItem(value: 'complete',
                  child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Mark Complete'))),
            const PopupMenuItem(value: 'edit',
                child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            const PopupMenuItem(value: 'delete',
                child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
          ],
        ),
      ),
    );
  }
}

// ── Task Form ─────────────────────────────────────────────────────────────────

class TaskFormScreen extends StatefulWidget {
  final MaintenanceTask? task;
  final List<Appliance> appliances;
  final List<HomeFeature> features;

  const TaskFormScreen({
    super.key,
    this.task,
    required this.appliances,
    required this.features,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late final TextEditingController _title, _freqDays, _nextDue, _notes;
  late String _itemType;
  late int _itemId;
  late int _priority;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title    = TextEditingController(text: t?.title ?? '');
    _freqDays = TextEditingController(text: (t?.frequencyDays ?? 0).toString());
    _nextDue  = TextEditingController(
        text: t?.nextDue ?? DateTime.now().toIso8601String().substring(0, 10));
    _notes    = TextEditingController(text: t?.notes ?? '');
    _itemType = t?.itemType ?? 'appliance';
    _itemId   = t?.itemId ?? (widget.appliances.firstOrNull?.id ?? widget.features.firstOrNull?.id ?? 0);
    _priority = t?.priority ?? 2;
  }

  @override
  void dispose() {
    for (var c in [_title, _freqDays, _nextDue, _notes]) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.tryParse(_nextDue.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) _nextDue.text = picked.toIso8601String().substring(0, 10);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final t = MaintenanceTask(
      id: widget.task?.id,
      title: _title.text.trim(),
      itemType: _itemType,
      itemId: _itemId,
      frequencyDays: int.tryParse(_freqDays.text) ?? 0,
      nextDue: _nextDue.text.trim(),
      lastDone: widget.task?.lastDone ?? '',
      priority: _priority,
      completed: widget.task?.completed ?? false,
      notes: _notes.text.trim(),
    );
    if (t.id == null) {
      await _db.insertTask(t);
    } else {
      await _db.updateTask(t);
    }
    if (mounted) Navigator.pop(context);
  }

  List<DropdownMenuItem<int>> _itemMenuItems() {
    if (_itemType == 'appliance') {
      return widget.appliances.map((a) =>
          DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.brand})'))).toList();
    }
    return widget.features.map((f) =>
        DropdownMenuItem(value: f.id, child: Text('${f.name} [${f.category}]'))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.task == null;
    final items = _itemMenuItems();

    if (!items.any((i) => i.value == _itemId)) {
      _itemId = items.firstOrNull?.value ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Add Task' : 'Edit Task'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_title, 'Task Title *', hint: 'e.g. Replace HVAC filter', required: true),
            const SizedBox(height: 4),
            const Text('Link to', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Appliance'),
                  value: 'appliance',
                  groupValue: _itemType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() {
                    _itemType = v!;
                    _itemId = widget.appliances.firstOrNull?.id ?? 0;
                  }),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Feature'),
                  value: 'feature',
                  groupValue: _itemType,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() {
                    _itemType = v!;
                    _itemId = widget.features.firstOrNull?.id ?? 0;
                  }),
                ),
              ),
            ]),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                  value: _itemId,
                  decoration: const InputDecoration(
                    labelText: 'Item *',
                    border: OutlineInputBorder(),
                  ),
                  items: items,
                  onChanged: (v) => setState(() => _itemId = v!),
                ),
              ),
            _field(_freqDays, 'Repeat every N days (0 = one-time)', hint: '0'),
            _datePicker('Next Due Date'),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('Low')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
            ),
            _field(_notes, 'Notes', maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {String? hint, bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: maxLines == 1 && label.contains('days')
            ? TextInputType.number
            : null,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _datePicker(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _nextDue,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: _pickDate,
      ),
    );
  }
}
