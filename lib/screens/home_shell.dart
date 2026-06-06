import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';
import 'week_settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Run penalty check once the service is ready after login.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPenalty());
  }

  Future<void> _checkPenalty() async {
    final svc = await ref.read(routineServiceProvider.future);
    if (svc == null || !mounted) return;
    await ref.read(authControllerProvider.notifier).applyWeeklyPenaltyCheck(svc);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final loc = ref.watch(localeProvider);
    String s(String key) => AppStrings.get(loc, key);
    final shellTitles = [s('shell.today'), s('shell.stats'), s('shell.week'), s('shell.settings')];

    // Also re-check penalty whenever the selected date changes (catches week rollover).
    ref.listen(selectedDateProvider, (_, __) => _checkPenalty());

    return Scaffold(
      appBar: AppBar(
        title: Text(shellTitles[_index]),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          StatsScreen(),
          WeekSettingsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => TodayActions.addRoutine(context, ref),
              icon: const Icon(Icons.add),
              label: Text(s('today.add')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.today_outlined), selectedIcon: const Icon(Icons.today), label: s('nav.today')),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: s('nav.stats')),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: s('nav.week')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: s('nav.settings')),
        ],
      ),
    );
  }
}
