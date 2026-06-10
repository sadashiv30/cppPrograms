import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/maintenance_task.dart';
import '../models/appliance.dart';
import '../models/home_feature.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_state.dart';
import '../theme/app_theme.dart';

enum _Filter { all, overdue, upcoming, done }

class TasksScreen extends ConsumerStatefulWidget {
  final int? highlightId;
  const TasksScreen({super.key, this.highlightId});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  _Filter _filter = _Filter.all;

  String _itemName(MaintenanceTask t, List<Appliance> ap, List<HomeFeature> fe) {
    if (t.itemType == 'appliance') {
      final a = ap.where((a) => a.id == t.itemId).firstOrNull;
      return a != null ? '${a.name} · ${a.brand}'.trim() : 'Unknown';
    }
    final f = fe.where((f) => f.id == t.itemId).firstOrNull;
    return f != null ? '${f.name} · ${f.category}' : 'Unknown';
  }

  List<MaintenanceTask> _applyFilter(List<MaintenanceTask> all) =>
      switch (_filter) {
        _Filter.overdue  => all.where((t) => t.isOverdue).toList(),
        _Filter.upcoming => all.where((t) => t.isDueSoon(30) && !t.isOverdue).toList(),
        _Filter.done     => all.where((t) => t.completed).toList(),
        _Filter.all      => all.where((t) => !t.completed).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final tasksAsync  = ref.watch(tasksProvider);
    final appliances  = ref.watch(appliancesProvider).value ?? [];
    final features    = ref.watch(featuresProvider).value ?? [];

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        final filtered = _applyFilter(tasks);
        final overdueCount  = tasks.where((t) => t.isOverdue).length;
        final upcomingCount = tasks.where((t) => t.isDueSoon(30) && !t.isOverdue).length;

        return Scaffold(
          body: Column(
            children: [
              _FilterBar(
                selected: _filter,
                overdueCount: overdueCount,
                upcomingCount: upcomingCount,
                onChanged: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(tasksProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => TaskTile(
                            task: filtered[i],
                            itemName: _itemName(filtered[i], appliances, features),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (appliances.isNotEmpty || features.isNotEmpty) ...[
                FloatingActionButton.small(
                  heroTag: 'templates',
                  onPressed: () => _showTemplates(context, appliances, features),
                  tooltip: 'Seasonal Templates',
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(height: 8),
              ],
              FloatingActionButton.extended(
                heroTag: 'add_task',
                onPressed: (appliances.isEmpty && features.isEmpty)
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add an appliance or home feature first.')),
                        )
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(
                              appliances: appliances,
                              features: features,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return switch (_filter) {
      _Filter.overdue  => const EmptyState(
          icon: Icons.check_circle_outline,
          title: 'No overdue tasks!',
          subtitle: 'You\'re all caught up. Great job keeping up with maintenance.',
        ),
      _Filter.upcoming => const EmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'Nothing due soon',
          subtitle: 'No tasks due in the next 30 days.',
        ),
      _Filter.done     => const EmptyState(
          icon: Icons.history,
          title: 'No completed tasks',
          subtitle: 'Tasks marked as done will appear here.',
        ),
      _Filter.all      => const EmptyState(
          icon: Icons.task_outlined,
          title: 'No tasks yet',
          subtitle: 'Tap + to schedule your first maintenance task.',
        ),
    };
  }

  void _showTemplates(BuildContext ctx, List<Appliance> ap, List<HomeFeature> fe) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TemplatesSheet(appliances: ap, features: fe),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _Filter selected;
  final int overdueCount;
  final int upcomingCount;
  final ValueChanged<_Filter> onChanged;

  const _FilterBar({
    required this.selected,
    required this.overdueCount,
    required this.upcomingCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('Active', _Filter.all),
            const SizedBox(width: 8),
            _chip('Overdue${overdueCount > 0 ? ' ($overdueCount)' : ''}', _Filter.overdue,
                color: overdueCount > 0 ? AppTheme.overdueColor : null),
            const SizedBox(width: 8),
            _chip('30 Days${upcomingCount > 0 ? ' ($upcomingCount)' : ''}', _Filter.upcoming,
                color: upcomingCount > 0 ? AppTheme.upcomingColor : null),
            const SizedBox(width: 8),
            _chip('Completed', _Filter.done),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _Filter f, {Color? color}) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      final active = selected == f;
      final c = color ?? cs.primary;
      return GestureDetector(
        onTap: () => onChanged(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? c : c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? c : c.withOpacity(0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : c,
            ),
          ),
        ),
      );
    });
  }
}

// ── Seasonal Templates ────────────────────────────────────────────────────────

class _TemplatesSheet extends ConsumerWidget {
  final List<Appliance> appliances;
  final List<HomeFeature> features;

  const _TemplatesSheet({required this.appliances, required this.features});

  static const _templates = {
    'Spring Checklist': [
      ('Test smoke & CO detectors', 365),
      ('Check roof for winter damage', 365),
      ('Clean gutters', 180),
      ('Service AC before summer', 365),
      ('Inspect foundation for cracks', 365),
      ('Start irrigation system', 365),
    ],
    'Fall Checklist': [
      ('Winterize irrigation system', 365),
      ('Clean dryer vent', 365),
      ('Check weatherstripping on doors', 365),
      ('Service furnace before winter', 365),
      ('Clean gutters of leaves', 180),
      ('Check attic insulation', 730),
    ],
    'Monthly Routine': [
      ('Replace HVAC filter', 90),
      ('Test smoke detectors', 30),
      ('Clean dishwasher filter', 30),
      ('Run washer cleaning cycle', 30),
      ('Check water softener salt', 30),
    ],
    'Annual Checks': [
      ('Flush water heater', 365),
      ('Check electrical panel', 730),
      ('Inspect roof & flashing', 365),
      ('Service garage door', 365),
      ('Deep clean refrigerator coils', 365),
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 8),
              Text('Seasonal Templates',
                  style: Theme.of(context).textTheme.titleLarge),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: _templates.entries
                  .map((e) => _templateCard(context, ref, e.key, e.value))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(BuildContext ctx, WidgetRef ref, String name,
      List<(String, int)> tasks) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(name, style: Theme.of(ctx).textTheme.titleMedium),
        subtitle: Text('${tasks.length} tasks',
            style: Theme.of(ctx).textTheme.bodyMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          ...tasks.map((t) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.task_outlined, size: 18),
                title: Text(t.$1, style: const TextStyle(fontSize: 13)),
                subtitle: Text('Every ${t.$2}d'),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => _addAll(ctx, ref, tasks),
              child: Text('Add $name'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAll(BuildContext ctx, WidgetRef ref,
      List<(String, int)> tasks) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Default to first feature if available, else first appliance
    final String itemType;
    final int itemId;
    if (features.isNotEmpty) {
      itemType = 'feature';
      itemId = features.first.id!;
    } else {
      itemType = 'appliance';
      itemId = appliances.first.id!;
    }

    for (final t in tasks) {
      await ref.read(tasksProvider.notifier).add(MaintenanceTask(
            title: t.$1,
            itemType: itemType,
            itemId: itemId,
            frequencyDays: t.$2,
            nextDue: today,
            priority: 2,
          ));
    }

    if (ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('${tasks.length} tasks added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Task Form ─────────────────────────────────────────────────────────────────

class TaskFormScreen extends ConsumerStatefulWidget {
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
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title, _freqDays, _nextDue, _notes;
  late String _itemType;
  late int _itemId;
  late int _priority;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title    = TextEditingController(text: t?.title ?? '');
    _freqDays = TextEditingController(text: (t?.frequencyDays ?? 90).toString());
    _nextDue  = TextEditingController(
        text: t?.nextDue ?? DateTime.now().toIso8601String().substring(0, 10));
    _notes    = TextEditingController(text: t?.notes ?? '');
    _itemType = t?.itemType ?? (widget.appliances.isNotEmpty ? 'appliance' : 'feature');
    _itemId   = t?.itemId ??
        (widget.appliances.firstOrNull?.id ?? widget.features.firstOrNull?.id ?? 0);
    _priority = t?.priority ?? 2;
  }

  @override
  void dispose() {
    for (final c in [_title, _freqDays, _nextDue, _notes]) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_nextDue.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _nextDue.text = picked.toIso8601String().substring(0, 10));
    }
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
      await ref.read(tasksProvider.notifier).add(t);
    } else {
      await ref.read(tasksProvider.notifier).update(t);
    }
    if (mounted) Navigator.pop(context);
  }

  List<DropdownMenuItem<int>> _itemMenuItems() {
    if (_itemType == 'appliance') {
      return widget.appliances.map((a) => DropdownMenuItem(
          value: a.id,
          child: Text('${a.name} · ${a.brand}'.trim()))).toList();
    }
    return widget.features.map((f) => DropdownMenuItem(
        value: f.id,
        child: Text('${f.name} · ${f.category}'))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.task == null;
    final items = _itemMenuItems();
    if (items.isNotEmpty && !items.any((i) => i.value == _itemId)) {
      _itemId = items.first.value!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'New Task' : 'Edit Task'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_title, 'Task title *', hint: 'e.g. Replace HVAC filter', required: true),
            const SizedBox(height: 4),
            Text('Link to', style: Theme.of(context).textTheme.labelSmall),
            Row(children: [
              Expanded(child: RadioListTile<String>(
                title: const Text('Appliance'),
                value: 'appliance',
                groupValue: _itemType,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() {
                  _itemType = v!;
                  _itemId = widget.appliances.firstOrNull?.id ?? 0;
                }),
              )),
              Expanded(child: RadioListTile<String>(
                title: const Text('Feature'),
                value: 'feature',
                groupValue: _itemType,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() {
                  _itemType = v!;
                  _itemId = widget.features.firstOrNull?.id ?? 0;
                }),
              )),
            ]),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                  value: _itemId,
                  decoration: const InputDecoration(labelText: 'Item *'),
                  items: items,
                  onChanged: (v) => setState(() => _itemId = v!),
                ),
              ),
            _field(_freqDays, 'Repeat every N days (0 = one-time)', hint: '90'),
            _datePicker(),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('🔴  High')),
                  DropdownMenuItem(value: 2, child: Text('🟠  Medium')),
                  DropdownMenuItem(value: 3, child: Text('🟢  Low')),
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
        decoration: InputDecoration(labelText: label, hintText: hint),
        maxLines: maxLines,
        keyboardType: label.contains('days') ? TextInputType.number : null,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _datePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _nextDue,
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Next due date',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        onTap: _pickDate,
      ),
    );
  }
}
