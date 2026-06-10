import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_profile.dart';
import '../models/home_feature.dart';
import '../providers/providers.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';

class PropertySetupScreen extends ConsumerStatefulWidget {
  const PropertySetupScreen({super.key});

  @override
  ConsumerState<PropertySetupScreen> createState() => _PropertySetupScreenState();
}

class _PropertySetupScreenState extends ConsumerState<PropertySetupScreen> {
  final _addressCtrl = TextEditingController();
  HomeProfile? _fetched;
  bool _loading = false;
  String? _error;

  // Which features to auto-create
  final Map<String, bool> _toImport = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill if a profile already exists
    final existing = ref.read(homeProfileProvider).value;
    if (existing != null) _addressCtrl.text = existing.fullAddress;
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final apiKey = ref.read(rentcastApiKeyProvider);
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) return;

    setState(() { _loading = true; _error = null; _fetched = null; });

    try {
      final result = await PropertyService.fetchByAddress(address, apiKey);
      final suggestions = _suggestedFeatures(result);
      setState(() {
        _fetched = result;
        _toImport.clear();
        for (final s in suggestions) _toImport[s.name] = true;
        _loading = false;
      });
    } on PropertyServiceException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Unexpected error: $e'; _loading = false; });
    }
  }

  List<HomeFeature> _suggestedFeatures(HomeProfile p) {
    final year = p.installDateFromYear;
    final features = <HomeFeature>[];

    if (p.heatingType != null && p.heatingType!.isNotEmpty) {
      features.add(HomeFeature(
        category: 'HVAC',
        name: 'Heating System',
        installDate: year ?? '',
        notes: p.heatingType!,
      ));
    }
    if (p.coolingType != null && p.coolingType!.isNotEmpty) {
      features.add(HomeFeature(
        category: 'HVAC',
        name: 'Cooling System',
        installDate: year ?? '',
        notes: p.coolingType!,
      ));
    }
    if (p.roofType != null && p.roofType!.isNotEmpty) {
      features.add(HomeFeature(
        category: 'Roof',
        name: 'Roof',
        installDate: year ?? '',
        notes: p.roofType!,
      ));
    }
    if (p.foundationType != null && p.foundationType!.isNotEmpty) {
      features.add(HomeFeature(
        category: 'Foundation',
        name: 'Foundation',
        installDate: year ?? '',
        notes: p.foundationType!,
      ));
    }
    if (p.hasPool == true) {
      features.add(const HomeFeature(
        category: 'Pool',
        name: 'Swimming Pool',
      ));
    }
    if (p.parkingType != null && p.parkingType!.isNotEmpty) {
      features.add(HomeFeature(
        category: 'Other',
        name: 'Parking',
        notes: p.parkingType!,
      ));
    }
    return features;
  }

  Future<void> _save() async {
    if (_fetched == null) return;

    // Save profile
    await ref.read(homeProfileProvider.notifier).save(_fetched!);

    // Create selected features
    final suggestions = _suggestedFeatures(_fetched!);
    final existing = ref.read(featuresProvider).value ?? [];

    for (final f in suggestions) {
      if (_toImport[f.name] == true) {
        final alreadyExists = existing.any(
          (e) => e.name == f.name && e.category == f.category,
        );
        if (!alreadyExists) {
          await ref.read(featuresProvider.notifier).add(f);
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Home profile saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(rentcastApiKeyProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Profile'),
        actions: [
          if (_fetched != null)
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // API key notice
          if (apiKey.isEmpty)
            _ApiKeyBanner(onSetKey: () => _showApiKeyDialog(context)),

          // Address search
          const SizedBox(height: 8),
          Text('Property Address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. 123 Main St, Springfield, IL',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _lookup(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _loading ? null : _lookup,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                  : const Icon(Icons.search),
            ),
          ]),

          // Error
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: _error!),
          ],

          // Results
          if (_fetched != null) ...[
            const SizedBox(height: 24),
            _PropertyCard(profile: _fetched!),
            const SizedBox(height: 20),

            // Feature import selection
            if (_toImport.isNotEmpty) ...[
              Text('Auto-create Home Features',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Based on the property data, these features will be added to your inventory.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: _toImport.entries.map((entry) => CheckboxListTile(
                    value: entry.value,
                    onChanged: (v) =>
                        setState(() => _toImport[entry.key] = v ?? false),
                    title: Text(entry.key),
                    secondary: Icon(
                      Icons.home_repair_service_outlined,
                      color: cs.primary,
                    ),
                    dense: true,
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Profile & Import Features',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],

          // Help section
          const SizedBox(height: 32),
          _HelpCard(hasApiKey: apiKey.isNotEmpty, onSetKey: () => _showApiKeyDialog(context)),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: ref.read(rentcastApiKeyProvider));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rentcast API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Get a free API key at rentcast.io (500 requests/month free).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Paste your Rentcast API key',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(rentcastApiKeyProvider.notifier).set(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Property card ─────────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  final HomeProfile profile;
  const _PropertyCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.home_outlined,
                  color: cs.onPrimaryContainer, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.address, style: Theme.of(context).textTheme.titleMedium),
                if (p.city.isNotEmpty || p.state.isNotEmpty)
                  Text('${p.city}, ${p.state} ${p.zip}'.trim(),
                      style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.propertyType != null)
                _Chip(icon: Icons.house_outlined, label: p.propertyType!),
              if (p.yearBuilt != null)
                _Chip(icon: Icons.calendar_today_outlined, label: 'Built ${p.yearBuilt}'),
              if (p.bedrooms != null)
                _Chip(icon: Icons.bed_outlined, label: '${p.bedrooms} bed'),
              if (p.bathrooms != null)
                _Chip(icon: Icons.bathtub_outlined,
                    label: '${p.bathrooms!.toStringAsFixed(p.bathrooms! % 1 == 0 ? 0 : 1)} bath'),
              if (p.sqft != null)
                _Chip(icon: Icons.square_foot_outlined,
                    label: '${p.sqft!.toStringAsFixed(0)} sq ft'),
              if (p.heatingType != null)
                _Chip(icon: Icons.local_fire_department_outlined,
                    label: p.heatingType!, color: AppTheme.upcomingColor),
              if (p.coolingType != null)
                _Chip(icon: Icons.air, label: p.coolingType!, color: Colors.blue),
              if (p.roofType != null)
                _Chip(icon: Icons.roofing, label: '${p.roofType} roof'),
              if (p.foundationType != null)
                _Chip(icon: Icons.foundation, label: p.foundationType!),
              if (p.hasPool == true)
                _Chip(icon: Icons.pool, label: 'Pool', color: Colors.blue),
              if (p.parkingType != null)
                _Chip(icon: Icons.garage_outlined, label: p.parkingType!),
            ],
          ),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── API key banner ────────────────────────────────────────────────────────────

class _ApiKeyBanner extends StatelessWidget {
  final VoidCallback onSetKey;
  const _ApiKeyBanner({required this.onSetKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.upcomingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.upcomingColor.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.key_outlined, color: AppTheme.upcomingColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Add a free Rentcast API key to auto-fetch property data.',
            style: TextStyle(color: AppTheme.upcomingColor, fontSize: 13),
          ),
        ),
        TextButton(
          onPressed: onSetKey,
          child: const Text('Set Key'),
        ),
      ]),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.overdueColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.overdueColor.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline, color: AppTheme.overdueColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: TextStyle(color: AppTheme.overdueColor, fontSize: 13)),
        ),
      ]),
    );
  }
}

// ── Help card ─────────────────────────────────────────────────────────────────

class _HelpCard extends StatelessWidget {
  final bool hasApiKey;
  final VoidCallback onSetKey;
  const _HelpCard({required this.hasApiKey, required this.onSetKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.help_outline, color: cs.primary, size: 18),
            const SizedBox(width: 8),
            Text('How it works', style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          const _HelpRow(
            icon: Icons.key_outlined,
            text: '1. Get a free API key from rentcast.io (500 lookups/month)',
          ),
          const _HelpRow(
            icon: Icons.search,
            text: '2. Enter your property address and tap search',
          ),
          const _HelpRow(
            icon: Icons.home_work_outlined,
            text: '3. Review the fetched data: bedrooms, heating, roof type and more',
          ),
          const _HelpRow(
            icon: Icons.checklist_outlined,
            text: '4. Choose which home features to auto-create, then save',
          ),
          if (!hasApiKey) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSetKey,
                icon: const Icon(Icons.key_outlined),
                label: const Text('Add Rentcast API Key'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HelpRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ]),
    );
  }
}
