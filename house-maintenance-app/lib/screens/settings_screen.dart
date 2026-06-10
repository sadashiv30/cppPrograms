import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../db/database_helper.dart';
import 'property_setup_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode          = ref.watch(themeModeProvider);
    final notificationsOn    = ref.watch(notificationsEnabledProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [

          // ── Appearance ────────────────────────────────────────
          _SectionHeader('Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 18)),
                    ButtonSegment(value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 18)),
                    ButtonSegment(value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 18)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).set(s.first),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ]),
          ),

          // ── Home Profile ──────────────────────────────────────
          _SectionHeader('Home Profile'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              Consumer(builder: (context, ref, _) {
                final profile = ref.watch(homeProfileProvider).value;
                return ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(profile != null ? profile.address : 'No property set'),
                  subtitle: Text(
                    profile != null
                        ? [
                            if (profile.yearBuilt != null) 'Built ${profile.yearBuilt}',
                            if (profile.bedrooms != null) '${profile.bedrooms} bed',
                            if (profile.sqft != null)
                              '${profile.sqft!.toStringAsFixed(0)} sq ft',
                          ].join(' · ')
                        : 'Tap to look up your property details',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PropertySetupScreen()),
                  ),
                );
              }),
            ]),
          ),

          // ── Notifications ─────────────────────────────────────
          _SectionHeader('Notifications'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Task reminders'),
                subtitle: const Text('Get reminded before tasks are due'),
                value: notificationsOn,
                onChanged: (_) =>
                    ref.read(notificationsEnabledProvider.notifier).toggle(),
              ),
              if (notificationsOn)
                const ListTile(
                  leading: Icon(Icons.info_outline, size: 18),
                  title: Text(
                    'Requires platform notification setup after flutter create.',
                    style: TextStyle(fontSize: 12),
                  ),
                  dense: true,
                ),
            ]),
          ),

          // ── Data ──────────────────────────────────────────────
          _SectionHeader('Data'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Storage'),
                subtitle: const Text('All data is stored on-device (SQLite)'),
                trailing: Icon(Icons.lock_outline, color: cs.primary, size: 18),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: cs.error),
                title: Text('Clear all data',
                    style: TextStyle(color: cs.error)),
                subtitle: const Text('Permanently delete everything'),
                onTap: () => _confirmClear(context),
              ),
            ]),
          ),

          // ── About ─────────────────────────────────────────────
          _SectionHeader('About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: const Text('House Maintenance'),
                subtitle: const Text('Version 2.0.0'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy'),
                subtitle: const Text('No data leaves your device. Ever.'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Open source licenses'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'House Maintenance',
                  applicationVersion: '2.0.0',
                ),
              ),
            ]),
          ),

          const SizedBox(height: 40),

          // App icon + tagline
          Center(
            child: Column(children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.light().colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.home_work_outlined,
                    size: 36,
                    color: AppTheme.light().colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 8),
              Text('Your home, always maintained.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This will permanently delete all appliances, features, tasks, and history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('task_completions');
      await db.delete('maintenance_tasks');
      await db.delete('home_features');
      await db.delete('appliances');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.primary,
              )),
    );
  }
}
