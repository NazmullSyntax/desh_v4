import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/hotel_provider.dart' show bottomNavIndexProvider;
import '../home/home_screen.dart';
import '../guide/division_list_screen.dart';
import '../trip_planner/trip_planner_screen.dart';
import '../profile/profile_screen.dart';

/// Persistent shell that hosts the 4 primary destinations behind the
/// bottom navigation bar. AI Assistant is reachable via a floating
/// action button from Home rather than occupying a 5th tab, keeping the
/// nav bar uncluttered per modern travel-app conventions (Airbnb, Google
/// Travel use 4-5 tabs max).
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _screens = [
    HomeScreen(),
    DivisionListScreen(),
    TripPlannerScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = widget.initialIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(bottomNavIndexProvider.notifier).state = i,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Guide'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note_rounded), label: 'Trip Planner'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
