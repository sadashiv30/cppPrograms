import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'appliances_screen.dart';
import 'features_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Appliances', 'Features', 'Tasks'];

  @override
  Widget build(BuildContext context) {
    final overdueCount = ref.watch(dashboardProvider).whenData((d) => d.overdueCount).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index],
            style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          AppliancesScreen(),
          FeaturesScreen(),
          TasksScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Appliances',
          ),
          const NavigationDestination(
            icon: Icon(Icons.home_repair_service_outlined),
            selectedIcon: Icon(Icons.home_repair_service),
            label: 'Features',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: overdueCount > 0,
              label: Text('$overdueCount'),
              child: const Icon(Icons.task_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: overdueCount > 0,
              label: Text('$overdueCount'),
              child: const Icon(Icons.task),
            ),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}
