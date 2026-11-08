import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/amizone_service.dart';
import '../services/scraper_service.dart';
import '../services/theme_service.dart';
import 'amizone_web_login_screen.dart';

enum _Stage { idle, verifying, scrapingAttendance, scrapingLibrary }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignedIn,
    this.initialUsername,
    this.startInAddMode = false,
  });

  final VoidCallback onSignedIn;
  final String? initialUsername;
  final bool startInAddMode;

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
  late bool _showNewAccountForm;

  bool get _busy => _stage != _Stage.idle;

  @override
  void initState() {
    super.initState();
    _showNewAccountForm = widget.startInAddMode || AmizoneService.instance.accounts.isEmpty;
    _userController.text = widget.initialUsername ?? '';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accounts = AmizoneService.instance.accounts;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () => ThemeService.instance.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: accounts.isNotEmpty && !_showNewAccountForm
                  ? _buildMacOsUserSelection(context, accounts)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBrand(),
                        const SizedBox(height: 24),
                        if (accounts.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() => _showNewAccountForm = false),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Back to User Accounts'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
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
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school_outlined, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          'Ami-Track',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in with your Amizone account to sync your attendance, marks, syllabus, and examination schedule.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.4, color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
        ),
      ],
    );
  }

  /// macOS-style user profile selection screen
  Widget _buildMacOsUserSelection(BuildContext context, List<AmizoneAccount> accounts) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App logo & Lock header
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.school_outlined, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Ami-Track',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your account to continue',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 32),

        // User accounts grid/list
        Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: accounts.map((account) {
            final isCurrent = AmizoneService.instance.isCurrent(account.username);
            final initial = account.username.trim().isEmpty
                ? '?'
                : account.username.trim().substring(0, 1).toUpperCase();

            return InkWell(
              onTap: _busy
                  ? null
                  : () async {
                      setState(() => _stage = _Stage.verifying);
                      final ok = await AmizoneService.instance.switchTo(account.username);
                      if (!mounted) return;
                      setState(() => _stage = _Stage.idle);
                      if (ok) {
                        widget.onSignedIn();
                      } else {
                        // Needs re-auth
                        setState(() {
                          _showNewAccountForm = true;
                          _userController.text = account.username;
                          _error = 'Session expired. Please enter password to re-authenticate.';
                        });
                      }
                    },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isCurrent ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar circle
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: isCurrent
                              ? const Color(0xFF1E3A8A)
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: account.hasSession ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.cardColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      account.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      account.courses.isNotEmpty
                          ? '${account.courses.length} subjects'
                          : 'Signed in',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        await AmizoneService.instance.removeAccount(account.username);
                        if (mounted) setState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 36),

        // New account login button (with password)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6)),
          ),
          onPressed: () {
            setState(() {
              _showNewAccountForm = true;
              _userController.clear();
              _passController.clear();
              _error = null;
            });
          },
          icon: const Icon(Icons.person_add_alt, size: 18),
          label: const Text(
            'New Account Login (With Password)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
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
              Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Amizone login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userController,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onSubmitted: (_) => _passFocus.requestFocus(),
            decoration: InputDecoration(
              labelText: 'Amizone-ID',
              hintText: 'e.g. XXXXXXXX',
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
                backgroundColor: const Color(0xFF1E3A8A),
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
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
    final theme = Theme.of(context);
    final steps = <(String, bool, bool)>[
      (
        'Signing in on Amizone',
        _stage == _Stage.verifying,
        _stage != _Stage.verifying,
      ),
      (
        'Scraping attendance, marks & syllabus',
        _stage == _Stage.scrapingAttendance,
        _stage == _Stage.scrapingLibrary,
      ),
      (
        'Scraping exam schedule & results',
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
                    ? const Icon(Icons.check_circle, size: 18, color: Colors.green)
                    : active
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Icon(Icons.radio_button_unchecked, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your password is used only to sign in to s.amizone.net and is never '
            'stored. Each account’s session stays on this device, so you can switch '
            'between them later.',
            style: TextStyle(fontSize: 11, height: 1.4, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
            'works on Android and iOS. Run Ami-Track on your phone to sign in.';
      });
      return;
    }

    setState(() {
      _error = null;
      _stage = _Stage.verifying;
    });

    final amizone = AmizoneService.instance;

    try {
      await CookieManager.instance().deleteAllCookies();
    } catch (error) {
      debugPrint('Could not clear the portal cookies: $error');
    }
    if (!mounted) return;

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

Future<void> openAccountLogin(BuildContext context, {String? username}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => LoginScreen(
        onSignedIn: () => Navigator.of(context).pop(),
        initialUsername: username,
        startInAddMode: true,
      ),
    ),
  );
}
