import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/providers.dart';
import '../models/appliance.dart';
import '../widgets/empty_state.dart';

class AppliancesScreen extends ConsumerStatefulWidget {
  const AppliancesScreen({super.key});

  @override
  ConsumerState<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends ConsumerState<AppliancesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final appliancesAsync = ref.watch(appliancesProvider);

    return appliancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final filtered = _search.isEmpty
            ? items
            : items.where((a) =>
                a.name.toLowerCase().contains(_search.toLowerCase()) ||
                a.brand.toLowerCase().contains(_search.toLowerCase()) ||
                a.location.toLowerCase().contains(_search.toLowerCase())).toList();

        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SearchBar(
                  hintText: 'Search appliances…',
                  leading: const Icon(Icons.search, size: 20),
                  onChanged: (v) => setState(() => _search = v),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.kitchen_outlined,
                        title: _search.isNotEmpty
                            ? 'No results for "$_search"'
                            : 'No appliances yet',
                        subtitle: _search.isNotEmpty
                            ? 'Try a different search term'
                            : 'Tap + to add your first appliance',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(appliancesProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _ApplianceCard(
                            appliance: filtered[i],
                            onEdit: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApplianceFormScreen(
                                      appliance: filtered[i]),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApplianceFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Appliance'),
          ),
        );
      },
    );
  }
}

// ── Appliance card with Slidable ──────────────────────────────────────────────

class _ApplianceCard extends ConsumerWidget {
  final Appliance appliance;
  final VoidCallback onEdit;

  const _ApplianceCard({required this.appliance, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = appliance;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(a.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Appliance'),
                    content: Text('Delete "${a.name}"?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(appliancesProvider.notifier).delete(a.id!);
                }
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            ),
          ],
        ),
        child: Card(
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    a.name.isEmpty ? '?' : a.name[0].toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: cs.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (a.brand.isNotEmpty || a.model.isNotEmpty)
                        Text('${a.brand} ${a.model}'.trim(),
                            style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        if (a.location.isNotEmpty)
                          _tag(context,
                              icon: Icons.location_on_outlined,
                              label: a.location,
                              color: cs.secondary),
                        if (a.warrantyExpiry.isNotEmpty)
                          _warrantyChip(context, a),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant, size: 20),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _warrantyChip(BuildContext context, Appliance a) {
    final expired = a.warrantyExpired;
    final color = expired ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(expired ? Icons.warning_amber_outlined : Icons.verified_outlined,
            size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          expired ? 'Warranty expired' : 'Until ${a.warrantyExpiry}',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }
}

// ── Appliance form ────────────────────────────────────────────────────────────

class ApplianceFormScreen extends ConsumerStatefulWidget {
  final Appliance? appliance;
  const ApplianceFormScreen({super.key, this.appliance});

  @override
  ConsumerState<ApplianceFormScreen> createState() => _ApplianceFormScreenState();
}

class _ApplianceFormScreenState extends ConsumerState<ApplianceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _brand, _model, _serial,
      _location, _install, _warranty, _notes;

  @override
  void initState() {
    super.initState();
    final a = widget.appliance;
    _name     = TextEditingController(text: a?.name ?? '');
    _brand    = TextEditingController(text: a?.brand ?? '');
    _model    = TextEditingController(text: a?.model ?? '');
    _serial   = TextEditingController(text: a?.serialNumber ?? '');
    _location = TextEditingController(text: a?.location ?? '');
    _install  = TextEditingController(text: a?.installDate ?? '');
    _warranty = TextEditingController(text: a?.warrantyExpiry ?? '');
    _notes    = TextEditingController(text: a?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _model, _serial, _location, _install, _warranty, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(ctrl.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) ctrl.text = picked.toIso8601String().substring(0, 10);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final a = Appliance(
      id: widget.appliance?.id,
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      serialNumber: _serial.text.trim(),
      location: _location.text.trim(),
      installDate: _install.text.trim(),
      warrantyExpiry: _warranty.text.trim(),
      notes: _notes.text.trim(),
    );
    if (a.id == null) {
      await ref.read(appliancesProvider.notifier).add(a);
    } else {
      await ref.read(appliancesProvider.notifier).edit(a);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appliance == null ? 'New Appliance' : 'Edit Appliance'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Name *', hint: 'e.g. Refrigerator', required: true),
            _field(_brand, 'Brand', hint: 'e.g. Samsung'),
            _field(_model, 'Model number', hint: 'e.g. RF28R7551SR'),
            _field(_serial, 'Serial number'),
            _field(_location, 'Location', hint: 'e.g. Kitchen'),
            _datePicker(_install, 'Install date'),
            _datePicker(_warranty, 'Warranty expiry'),
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
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _datePicker(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        onTap: () => _pickDate(ctrl),
      ),
    );
  }
}
