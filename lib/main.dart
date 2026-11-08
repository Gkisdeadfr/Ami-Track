import 'package:flutter/material.dart';

import 'screens/assignments_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/exams_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pyq_screen.dart';
import 'screens/syllabus_screen.dart';
import 'services/amizone_service.dart';
import 'services/scraper_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.instance.init();
  await AmizoneService.instance.init();
  final activeUser = AmizoneService.instance.username;
  await StorageService.instance.bindAccount(activeUser);
  await ScraperService.instance.bindAccount(activeUser);
  runApp(const AmiTrackApp());
}

class AmiTrackApp extends StatelessWidget {
  const AmiTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Ami-Track',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          home: const AppRoot(),
        );
      },
    );
  }
}

/// Decides what the app opens to: the sign-in screen, or (when a stored
/// Amizone session is still valid) straight to the dashboard.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

enum _Phase { checking, signedOut, signedIn }

class _AppRootState extends State<AppRoot> {
  _Phase _phase = _Phase.checking;

  @override
  void initState() {
    super.initState();
    AmizoneService.instance.addListener(_onSessionChanged);
    _restoreSession();
  }

  @override
  void dispose() {
    AmizoneService.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Drops back to the sign-in screen as soon as the portal session expires
  /// (a sync can discover that at any time).
  void _onSessionChanged() {
    if (_phase == _Phase.signedIn && !AmizoneService.instance.isSignedIn) {
      setState(() => _phase = _Phase.signedOut);
    }
  }

  Future<void> _restoreSession() async {
    // When the app starts, show the user selection screen (macOS style)
    // allowing 1-tap login to existing accounts without password,
    // or new account login with password.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _phase = _Phase.signedOut);
  }

  Future<void> _signOut() async {
    final stillSignedIn = await AmizoneService.instance.signOut();
    if (!mounted) return;
    if (!stillSignedIn) setState(() => _phase = _Phase.signedOut);
  }

  void _onSwitchAccount() {
    setState(() => _phase = _Phase.signedOut);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.checking:
        return const _SplashScreen();
      case _Phase.signedOut:
        return LoginScreen(
          onSignedIn: () => setState(() => _phase = _Phase.signedIn),
        );
      case _Phase.signedIn:
        return MainNavigationScreen(
          onSignOut: _signOut,
          onSwitchAccount: _onSwitchAccount,
        );
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.indigo.shade700, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, color: Colors.white, size: 56),
              SizedBox(height: 16),
              Text(
                'Ami-Track',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(height: 12),
              Text(
                'Checking your Amizone session…',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    required this.onSignOut,
    this.onSwitchAccount,
  });

  final VoidCallback onSignOut;
  final VoidCallback? onSwitchAccount;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabSelect(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onTabChange: (tabIdx) {
          setState(() {
            // tabIdx mapping: 0 -> Exams(2), 1 -> Syllabus(3), 2 -> Assignments(4)
            if (tabIdx == 0) _currentIndex = 2;
            if (tabIdx == 1) _currentIndex = 3;
            if (tabIdx == 2) _currentIndex = 4;
          });
        },
        onSignOut: widget.onSignOut,
        onSwitchAccount: widget.onSwitchAccount,
      ),
      const AttendanceScreen(),
      const ExamsScreen(),
      const SyllabusScreen(),
      const AssignmentsScreen(),
      const PYQScreen(),
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelect,
        indicatorColor: isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.22)
            : Colors.indigo.shade100,
        backgroundColor: theme.cardColor,
        elevation: 8,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: theme.colorScheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.co_present_outlined),
            selectedIcon: Icon(Icons.co_present, color: theme.colorScheme.primary),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
            label: 'Exams',
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl, color: theme.colorScheme.primary),
            label: 'Syllabus',
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: theme.colorScheme.primary),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared, color: theme.colorScheme.primary),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
