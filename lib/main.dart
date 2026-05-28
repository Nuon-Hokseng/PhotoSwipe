import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'features/ai/ai_module.dart';
import 'features/ai/providers/ai_provider.dart';
import 'features/analytics/analytics_module.dart';
import 'features/analytics/providers/analytics_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/swipe_screen.dart';
import 'services/supabase/supabase_client.dart';
import 'utils/app_colors.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await SupabaseClientWrapper.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Request photo library access on Android 13+ (READ_MEDIA_IMAGES)
  // and storage access on older Android. Silently continues if denied.
  await Permission.photos.request();
  await Permission.storage.request();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AnalyticsProvider>(
            create: (_) => AnalyticsModule.provider),
        ChangeNotifierProvider<AiProvider>(
            create: (_) => AiModule.provider),
      ],
      child: const PhotoSwipeApp(),
    ),
  );
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
        ],
      ),
    );
  }
}
