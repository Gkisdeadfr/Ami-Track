import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/amizone_service.dart';
import '../services/scraper_service.dart';
import 'amizone_web_login_screen.dart';

enum _Stage { idle, verifying, scrapingAttendance, scrapingLibrary }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final FocusNode _passFocus = FocusNode();

  _Stage _stage = _Stage.idle;
  bool _showPassword = false;
  String? _error;

  bool get _busy => _stage != _Stage.idle;

  @override
  void initState() {
    super.initState();
    _userController.text = AmizoneService.instance.username;
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrand(),
                  const SizedBox(height: 26),
                  _buildForm(context),
                  const SizedBox(height: 18),
                  _buildPrivacyNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade800, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school_outlined, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        const Text(
          'CampusTrack',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in with your Amizone account. We scrape your attendance, marks '
          'and semester resources, then keep them on this device.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: Colors.indigo.shade800),
              const SizedBox(width: 8),
              Text(
                'Amizone login',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _userController,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onSubmitted: (_) => _passFocus.requestFocus(),
            decoration: InputDecoration(
              labelText: 'Enrollment number',
              hintText: 'e.g. A23XXXXXXXX',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passController,
            focusNode: _passFocus,
            enabled: !_busy,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Amizone password',
              prefixIcon: const Icon(Icons.key_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.login, size: 18),
              label: Text(
                _busy ? 'Working…' : 'Sign in & sync',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 14),
            _buildProgress(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final steps = <(String, bool, bool)>[
      (
        'Signing in on Amizone',
        _stage == _Stage.verifying,
        _stage != _Stage.verifying,
      ),
      (
        'Scraping attendance & internal marks',
        _stage == _Stage.scrapingAttendance,
        _stage == _Stage.scrapingLibrary,
      ),
      (
        'Scraping the NexAcad library',
        _stage == _Stage.scrapingLibrary,
        false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        final (label, active, done) = step;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: done
                    ? Icon(Icons.check_circle, size: 18, color: Colors.green.shade600)
                    : active
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Icon(Icons.radio_button_unchecked, size: 16, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? const Color(0xFF0F172A) : Colors.grey.shade600,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrivacyNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your password is used only to sign in to s.amizone.net and is never '
            'stored. Only the Amizone session and your scraped data stay on this device.',
            style: TextStyle(fontSize: 11, height: 1.4, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    final user = _userController.text.trim();
    final pass = _passController.text;

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter both your enrollment number and Amizone password.');
      return;
    }

    if (kIsWeb) {
      setState(() {
        _error = 'Amizone sign-in opens the portal inside the app, which only '
            'works on Android and iOS. Run CampusTrack on your phone to sign in.';
      });
      return;
    }

    setState(() {
      _error = null;
      _stage = _Stage.verifying;
    });

    final amizone = AmizoneService.instance;

    // Amizone asks for a Cloudflare check on every sign-in, so the portal's own
    // page (in the WebView) is the only reliable way to authenticate. It is
    // pre-filled, so the student just taps LOGIN.
    final cookies = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => AmizoneWebLoginScreen(username: user, password: pass),
      ),
    );
    if (!mounted) return;
    if (cookies == null) {
      setState(() {
        _stage = _Stage.idle;
        _error = 'Sign-in was cancelled before Amizone confirmed the session.';
      });
      return;
    }

    setState(() => _stage = _Stage.scrapingAttendance);
    final scraped = await amizone.completeWebSignIn(cookies, user: user);
    if (!mounted) return;
    if (!scraped) {
      setState(() {
        _stage = _Stage.idle;
        _error = amizone.statusMessage ?? 'Amizone did not accept the session.';
      });
      return;
    }

    setState(() => _stage = _Stage.scrapingLibrary);
    await ScraperService.instance.syncFromNexacad(
      enrolledCodes: amizone.courses.map((c) => c.subjectCode).toList(),
    );
    if (!mounted) return;

    setState(() => _stage = _Stage.idle);
    widget.onSignedIn();
  }
}
