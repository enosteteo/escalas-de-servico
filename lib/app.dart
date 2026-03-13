import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/providers/schedule_notifier.dart';
import 'core/providers/settings_notifier.dart';
import 'core/providers/volunteer_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/schedule/presentation/schedule_generation_screen.dart';
import 'features/schedule/presentation/schedule_view_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/volunteers/presentation/volunteers_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/volunteers', builder: (_, __) => const VolunteersScreen()),
        GoRoute(path: '/schedule/generate', builder: (_, __) => const ScheduleGenerationScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/schedule/:id',
      builder: (_, state) => ScheduleViewScreen(scheduleId: state.pathParameters['id']!),
    ),
  ],
);

class IgrejaEmEscalaApp extends StatelessWidget {
  const IgrejaEmEscalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VolunteerNotifier()),
        ChangeNotifierProvider(create: (_) => ScheduleNotifier()),
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
      ],
      child: Consumer<SettingsNotifier>(
        builder: (_, settings, __) => MaterialApp.router(
          title: 'Igreja em Escala',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Início', path: '/'),
    (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Voluntários', path: '/volunteers'),
    (icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Gerar', path: '/schedule/generate'),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Configurações', path: '/settings'),
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;
    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}
