import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/appliance.dart';

class AppliancesScreen extends StatefulWidget {
  const AppliancesScreen({super.key});

  @override
  State<AppliancesScreen> createState() => _AppliancesScreenState();
}

class _AppliancesScreenState extends State<AppliancesScreen> {
  final _db = DatabaseHelper.instance;
  List<Appliance> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getAppliances();
    setState(() => _items = items);
  }

  Future<void> _delete(Appliance a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Appliance'),
        content: Text('Delete "${a.name}"? Associated tasks will remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteAppliance(a.id!);
      _load();
    }
  }

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
                itemBuilder: (_, i) => _applianceCard(_items[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ApplianceFormScreen()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Appliance'),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.kitchen, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('No appliances yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Tap + to add your first appliance', style: TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _applianceCard(Appliance a) {
    final warrantyBadge = a.warrantyExpired
        ? const Chip(label: Text('Expired', style: TextStyle(fontSize: 11)),
            backgroundColor: Colors.red, padding: EdgeInsets.zero)
        : a.warrantyExpiry.isNotEmpty
            ? Chip(label: Text('Until ${a.warrantyExpiry}', style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.green.shade100, padding: EdgeInsets.zero)
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(a.name.isEmpty ? '?' : a.name[0].toUpperCase()),
        ),
        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.brand.isNotEmpty || a.model.isNotEmpty)
              Text('${a.brand} ${a.model}'.trim()),
            if (a.location.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                Text(a.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            if (warrantyBadge != null) warrantyBadge,
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ApplianceFormScreen(appliance: a)));
              _load();
            } else if (v == 'delete') {
              await _delete(a);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
            const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'))),
          ],
        ),
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => ApplianceFormScreen(appliance: a)));
          _load();
        },
      ),
    );
  }
}

// ── Appliance Form ────────────────────────────────────────────────────────────

class ApplianceFormScreen extends StatefulWidget {
  final Appliance? appliance;
  const ApplianceFormScreen({super.key, this.appliance});

  @override
  State<ApplianceFormScreen> createState() => _ApplianceFormScreenState();
}

class _ApplianceFormScreenState extends State<ApplianceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late final TextEditingController _name, _brand, _model, _serial,
      _location, _installDate, _warrantyDate, _notes;

  @override
  void initState() {
    super.initState();
    final a = widget.appliance;
    _name        = TextEditingController(text: a?.name ?? '');
    _brand       = TextEditingController(text: a?.brand ?? '');
    _model       = TextEditingController(text: a?.model ?? '');
    _serial      = TextEditingController(text: a?.serialNumber ?? '');
    _location    = TextEditingController(text: a?.location ?? '');
    _installDate = TextEditingController(text: a?.installDate ?? '');
    _warrantyDate= TextEditingController(text: a?.warrantyExpiry ?? '');
    _notes       = TextEditingController(text: a?.notes ?? '');
  }

  @override
  void dispose() {
    for (var c in [_name, _brand, _model, _serial, _location, _installDate, _warrantyDate, _notes]) {
      c.dispose();
    }
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
    final a = Appliance(
      id: widget.appliance?.id,
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      serialNumber: _serial.text.trim(),
      location: _location.text.trim(),
      installDate: _installDate.text.trim(),
      warrantyExpiry: _warrantyDate.text.trim(),
      notes: _notes.text.trim(),
    );
    if (a.id == null) {
      await _db.insertAppliance(a);
    } else {
      await _db.updateAppliance(a);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.appliance == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Add Appliance' : 'Edit Appliance'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Name *', hint: 'e.g. Refrigerator', required: true),
            _field(_brand, 'Brand', hint: 'e.g. Samsung'),
            _field(_model, 'Model Number', hint: 'e.g. RF28R7551SR'),
            _field(_serial, 'Serial Number'),
            _field(_location, 'Location', hint: 'e.g. Kitchen'),
            _datePicker(_installDate, 'Install Date'),
            _datePicker(_warrantyDate, 'Warranty Expiry'),
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
