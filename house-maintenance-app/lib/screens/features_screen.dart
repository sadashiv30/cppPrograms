import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/providers.dart';
import '../models/home_feature.dart';
import '../widgets/empty_state.dart';

class FeaturesScreen extends ConsumerStatefulWidget {
  const FeaturesScreen({super.key});

  @override
  ConsumerState<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends ConsumerState<FeaturesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(featuresProvider);

    return featuresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        final filtered = _search.isEmpty
            ? items
            : items.where((f) =>
                f.name.toLowerCase().contains(_search.toLowerCase()) ||
                f.category.toLowerCase().contains(_search.toLowerCase()) ||
                f.location.toLowerCase().contains(_search.toLowerCase())).toList();

        // Group by category
        final grouped = <String, List<HomeFeature>>{};
        for (final f in filtered) {
          grouped.putIfAbsent(f.category, () => []).add(f);
        }

        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SearchBar(
                  hintText: 'Search features…',
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
                        icon: Icons.home_repair_service_outlined,
                        title: _search.isNotEmpty
                            ? 'No results for "$_search"'
                            : 'No home features yet',
                        subtitle: _search.isNotEmpty
                            ? 'Try a different search term'
                            : 'Add HVAC, plumbing, roof, and more',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(featuresProvider),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          children: grouped.entries.map((entry) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 6),
                                child: Row(children: [
                                  Icon(_categoryIcon(entry.key),
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(entry.key,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      )),
                                ]),
                              ),
                              ...entry.value.map((f) => _FeatureCard(
                                feature: f,
                                onEdit: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FeatureFormScreen(feature: f),
                                  ),
                                ),
                              )),
                            ],
                          )).toList(),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeatureFormScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Feature'),
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String cat) => switch (cat) {
    'HVAC'        => Icons.air,
    'Plumbing'    => Icons.water_drop_outlined,
    'Electrical'  => Icons.bolt,
    'Roof'        => Icons.roofing,
    'Foundation'  => Icons.foundation,
    'Landscaping' => Icons.grass,
    'Pool'        => Icons.pool,
    'Security'    => Icons.security,
    _             => Icons.home_repair_service_outlined,
  };
}

// ── Feature card with Slidable ────────────────────────────────────────────────

class _FeatureCard extends ConsumerWidget {
  final HomeFeature feature;
  final VoidCallback onEdit;

  const _FeatureCard({required this.feature, required this.onEdit});

  IconData _icon(String cat) => switch (cat) {
    'HVAC'        => Icons.air,
    'Plumbing'    => Icons.water_drop_outlined,
    'Electrical'  => Icons.bolt,
    'Roof'        => Icons.roofing,
    'Foundation'  => Icons.foundation,
    'Landscaping' => Icons.grass,
    'Pool'        => Icons.pool,
    'Security'    => Icons.security,
    _             => Icons.home_repair_service_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f  = feature;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(f.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Feature'),
                    content: Text('Delete "${f.name}"?'),
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
                  await ref.read(featuresProvider.notifier).delete(f.id!);
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
                  backgroundColor: cs.secondaryContainer,
                  child: Icon(_icon(f.category),
                      size: 22, color: cs.onSecondaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (f.location.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(f.location,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ]),
                        ),
                      if (f.lastServiced.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Last serviced: ${f.lastServiced}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feature form ──────────────────────────────────────────────────────────────

class FeatureFormScreen extends ConsumerStatefulWidget {
  final HomeFeature? feature;
  const FeatureFormScreen({super.key, this.feature});

  @override
  ConsumerState<FeatureFormScreen> createState() => _FeatureFormScreenState();
}

class _FeatureFormScreenState extends ConsumerState<FeatureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late final TextEditingController _name, _location, _install, _lastServiced, _notes;

  @override
  void initState() {
    super.initState();
    final f = widget.feature;
    _category    = f?.category ?? HomeFeature.categories.first;
    _name        = TextEditingController(text: f?.name ?? '');
    _location    = TextEditingController(text: f?.location ?? '');
    _install     = TextEditingController(text: f?.installDate ?? '');
    _lastServiced= TextEditingController(text: f?.lastServiced ?? '');
    _notes       = TextEditingController(text: f?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _location, _install, _lastServiced, _notes]) c.dispose();
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
    final f = HomeFeature(
      id: widget.feature?.id,
      category: _category,
      name: _name.text.trim(),
      location: _location.text.trim(),
      installDate: _install.text.trim(),
      lastServiced: _lastServiced.text.trim(),
      notes: _notes.text.trim(),
    );
    if (f.id == null) {
      await ref.read(featuresProvider.notifier).add(f);
    } else {
      await ref.read(featuresProvider.notifier).edit(f);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feature == null ? 'New Feature' : 'Edit Feature'),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: HomeFeature.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
            _field(_name, 'Name *', hint: 'e.g. Central AC, Water Heater', required: true),
            _field(_location, 'Location', hint: 'e.g. Basement, Attic'),
            _datePicker(_install, 'Install date'),
            _datePicker(_lastServiced, 'Last serviced'),
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
