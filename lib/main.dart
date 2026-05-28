import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'features/ai/ai_module.dart';
import 'features/ai/providers/ai_provider.dart';
import 'features/analytics/analytics_module.dart';
import 'features/analytics/providers/analytics_provider.dart';
import 'features/auto_mode/providers/auto_mode_provider.dart';
import 'features/auto_mode/screens/auto_mode_screen.dart';
import 'controllers/swipe_session_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/swipe_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request photo library access on Android 13+ (READ_MEDIA_IMAGES)
  // and storage access on older Android. Silently continues if denied.
  await Permission.photos.request();
  await Permission.storage.request();

  runApp(const PhotoSwipeApp());
}

class PhotoSwipeApp extends StatelessWidget {
  const PhotoSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AnalyticsProvider>(
            create: (_) => AnalyticsModule.provider),
        ChangeNotifierProvider<AiProvider>(create: (_) => AiModule.provider),
        ChangeNotifierProvider<AutoModeProvider>(
            create: (_) => AutoModeProvider()..init()),
      ],
      child: MaterialApp(
        title: 'PhotoSwipe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AutoModeProvider>().purgeExpired();
      }
    });
  }

  Future<void> _initSession() async {
    final controller = SwipeSessionController.instance;
    // Try to restore a previous session first; fall back to fresh load.
    final restored = await controller.restoreSession([]);
    if (!restored) {
      controller.loadFromDevice();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist session and flush deletes when app is backgrounded or closed.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      SwipeSessionController.instance.saveSession();
      SwipeSessionController.instance.commitDeletes();
    }
  }

  void _selectScreen(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onStartCleanup: () => _selectScreen(1)),
      const SwipeScreen(),
      DashboardScreen(onStartCleanup: () => _selectScreen(1)),
      const AutoModeScreen(),
    ];
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
          child: screens[_currentIndex],
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
          NavigationDestination(
            icon: Icon(Icons.auto_fix_high_rounded),
            selectedIcon: Icon(Icons.auto_fix_high_rounded),
            label: 'Auto',
          ),
        ],
      ),
    );
  }
}
