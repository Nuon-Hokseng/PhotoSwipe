import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/swipe_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const PhotoSwipeApp());
}

class PhotoSwipeApp extends StatelessWidget {
  const PhotoSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoSwipe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SwipeScreen(),
    DashboardScreen(),
  ];

  void _selectScreen(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moveForward = _currentIndex >= _previousIndex;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetTween = Tween<Offset>(
            begin: Offset(moveForward ? 0.08 : -0.08, 0.03),
            end: Offset.zero,
          );

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetTween.animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        animationDuration: const Duration(milliseconds: 360),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 76,
        backgroundColor: AppColors.card.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: _selectScreen,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Clean',
          ),
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_rounded),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
