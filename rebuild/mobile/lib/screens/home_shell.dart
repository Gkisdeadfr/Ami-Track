import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import 'amizone_login_screen.dart';
import 'sections.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  Future<void> _login() async {
    final username = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Amizone account'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Username / enrollment number',
              hintText: 'Enter your Amizone username',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    if (username == null || username.trim().isEmpty || !mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AmizoneLoginScreen(
          onAuthenticated: (cookies) => AppState.instance.completeLogin(
            username: username,
            cookies: cookies,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        if (state.api.token == null) {
          return _WelcomeScreen(onLogin: _login, error: state.error);
        }
        final pages = [
          DashboardSection(onOpenAttendance: () => setState(() => _tab = 1)),
          const AttendanceSection(),
          const LibrarySection(),
          const ProfileSection(),
        ];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ami-Track', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            actions: [
              if (state.offline)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Center(child: Chip(label: Text('OFFLINE', style: TextStyle(fontSize: 10)))),
                ),
              IconButton(
                tooltip: 'Sync',
                onPressed: state.loading ? null : () => state.sync(),
                icon: state.loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.error != null && state.data.isEmpty)
                _ErrorBanner(message: state.error!),
              Expanded(child: IndexedStack(index: _tab, children: pages)),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (value) => setState(() => _tab = value),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Overview'),
              NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Attendance'),
              NavigationDestination(icon: Icon(Icons.folder_open_rounded), label: 'Library'),
              NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.onLogin, this.error});
  final VoidCallback onLogin;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [Color(0xFF8795FF), Color(0xFF5869D8)]),
                ),
                child: const Icon(Icons.school_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text('Your campus,\nin one place.', style: TextStyle(fontSize: 38, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
              const SizedBox(height: 14),
              const Text('Attendance, academic records and study resources without the portal maze.', style: TextStyle(fontSize: 15, color: Colors.white60, height: 1.5)),
              const SizedBox(height: 30),
              if (error != null) _ErrorBanner(message: error!),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded),
                  label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Continue with Amizone')),
                ),
              ),
              const SizedBox(height: 12),
              const Text('You sign in on Amizone’s official page. Your password is never stored by Ami-Track.', style: TextStyle(fontSize: 11, color: Colors.white38, height: 1.4)),
              const Spacer(),
              const Text('AMI-TRACK  /  VERSION 2', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white30)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF42232C), borderRadius: BorderRadius.circular(12)),
    child: Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFFFFCCD3))),
  );
}
