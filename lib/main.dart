import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/scraper_service.dart';
import 'services/amizone_service.dart';
import 'screens/home_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/exams_screen.dart';
import 'screens/syllabus_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/pyq_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await ScraperService.instance.init();
  await AmizoneService.instance.init();
  runApp(const CampusTrackApp());
}

class CampusTrackApp extends StatelessWidget {
  const CampusTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0D9488),
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

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
      HomeScreen(onTabChange: (tabIdx) {
        setState(() {
          // tabIdx mapping: 0 -> Exams(2), 1 -> Syllabus(3), 2 -> Assignments(4)
          if (tabIdx == 0) _currentIndex = 2;
          if (tabIdx == 1) _currentIndex = 3;
          if (tabIdx == 2) _currentIndex = 4;
        });
      }),
      const AttendanceScreen(),
      const ExamsScreen(),
      const SyllabusScreen(),
      const AssignmentsScreen(),
      const PYQScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelect,
        indicatorColor: Colors.indigo.shade100,
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF1E3A8A)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.co_present_outlined),
            selectedIcon: Icon(Icons.co_present, color: Color(0xFF1E3A8A)),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF1E3A8A)),
            label: 'Exams',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl, color: Color(0xFF1E3A8A)),
            label: 'Syllabus',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: Color(0xFF1E3A8A)),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared, color: Color(0xFF1E3A8A)),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}
