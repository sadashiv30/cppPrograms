import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/home_feature.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final _db = DatabaseHelper.instance;
  List<HomeFeature> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getFeatures();
    setState(() => _items = items);
  }

  Future<void> _delete(HomeFeature f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Feature'),
        content: Text('Delete "${f.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteFeature(f.id!);
      _load();
    }
  }

  IconData _categoryIcon(String cat) => switch (cat) {
    'HVAC'        => Icons.air,
    'Plumbing'    => Icons.water_drop,
    'Electrical'  => Icons.bolt,
    'Roof'        => Icons.roofing,
    'Foundation'  => Icons.foundation,
    'Landscaping' => Icons.grass,
    'Pool'        => Icons.pool,
    'Security'    => Icons.security,
    _             => Icons.home_repair_service,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _items.isEmpty
          ? _empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                itemBuilder: (_, i) => _featureCard(_items[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FeatureFormScreen()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Feature'),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.home_repair_service, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('No home features yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Add HVAC, plumbing, roof, and more', style: TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _featureCard(HomeFeature f) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_categoryIcon(f.category), size: 20),
        ),
        title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.category, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            if (f.location.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                Text(f.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            if (f.lastServiced.isNotEmpty)
              Text('Last serviced: ${f.lastServiced}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => FeatureFormScreen(feature: f)));
              _load();
            } else if (v == 'delete') {
              await _delete(f);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
          ],
        ),
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => FeatureFormScreen(feature: f)));
          _load();
        },
      ),
    );
  }
}

// ── Feature Form ──────────────────────────────────────────────────────────────

class FeatureFormScreen extends StatefulWidget {
  final HomeFeature? feature;
  const FeatureFormScreen({super.key, this.feature});

  @override
  State<FeatureFormScreen> createState() => _FeatureFormScreenState();
}

class _FeatureFormScreenState extends State<FeatureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late String _category;
  late final TextEditingController _name, _location, _installDate, _lastServiced, _notes;

  @override
  void initState() {
    super.initState();
    final f = widget.feature;
    _category     = f?.category ?? HomeFeature.categories.first;
    _name         = TextEditingController(text: f?.name ?? '');
    _location     = TextEditingController(text: f?.location ?? '');
    _installDate  = TextEditingController(text: f?.installDate ?? '');
    _lastServiced = TextEditingController(text: f?.lastServiced ?? '');
    _notes        = TextEditingController(text: f?.notes ?? '');
  }

  @override
  void dispose() {
    for (var c in [_name, _location, _installDate, _lastServiced, _notes]) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
      installDate: _installDate.text.trim(),
      lastServiced: _lastServiced.text.trim(),
      notes: _notes.text.trim(),
    );
    if (f.id == null) {
      await _db.insertFeature(f);
    } else {
      await _db.updateFeature(f);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.feature == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Add Feature' : 'Edit Feature'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
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
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: HomeFeature.categories.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
            _field(_name, 'Name *', hint: 'e.g. Central AC, Water Heater', required: true),
            _field(_location, 'Location', hint: 'e.g. Basement, Attic'),
            _datePicker(_installDate, 'Install Date'),
            _datePicker(_lastServiced, 'Last Serviced'),
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
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => _pickDate(ctrl),
      ),
    );
  }
}
