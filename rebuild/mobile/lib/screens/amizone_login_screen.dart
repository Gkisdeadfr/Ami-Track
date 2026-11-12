import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AmizoneLoginScreen extends StatefulWidget {
  const AmizoneLoginScreen({super.key, required this.onAuthenticated});
  final Future<void> Function(Map<String, String> cookies) onAuthenticated;

  @override
  State<AmizoneLoginScreen> createState() => _AmizoneLoginScreenState();
}

class _AmizoneLoginScreenState extends State<AmizoneLoginScreen> {
  bool _handingOff = false;
  String? _message;

  Future<void> _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (_handingOff || url == null) return;
    final uri = Uri.tryParse(url.toString());
    if (uri == null ||
        uri.host != 's.amizone.net' ||
        !uri.path.toLowerCase().startsWith('/home')) {
      return;
    }

    // Amizone's own inline handler has a casing bug (loginForm vs loginform).
    // This only fixes form submission after the user has completed Turnstile.
    await controller.evaluateJavascript(source: """
      (function () {
        var form = document.getElementById('loginform');
        if (!form || window.__amiTrackSubmitFix) return;
        window.__amiTrackSubmitFix = true;
        document.addEventListener('click', function (event) {
          var button = event.target && event.target.closest
            ? event.target.closest('button[type="submit"], input[type="submit"]')
            : null;
          if (!button || !form.contains(button)) return;
          var captcha = form.querySelector('input[name="cf-turnstile-response"]');
          if (!captcha || !captcha.value) return;
          var token = form.querySelector('input[name="RecaptchaToken"]');
          if (token && !token.value) token.value = captcha.value;
          event.preventDefault();
          event.stopImmediatePropagation();
          form.submit();
        }, true);
      })();
    """);

    _handingOff = true;
    setState(() => _message = 'Amizone signed in. Securing your session…');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri('https://s.amizone.net/'),
      );
      final session = <String, String>{
        for (final cookie in cookies)
          if (cookie.name.isNotEmpty) cookie.name: cookie.value,
      };
      if (session.isEmpty) throw Exception('Amizone did not return a session cookie.');
      await widget.onAuthenticated(session);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _handingOff = false;
      if (mounted) setState(() => _message = 'Could not finish sign-in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Amizone')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF182440),
            child: Text(
              _message ??
                  'Sign in on the official Amizone page and complete Cloudflare verification. '
                      'Ami-Track never asks you to bypass the check.',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          const Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri('https://s.amizone.net/')),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                thirdPartyCookiesEnabled: true,
                sharedCookiesEnabled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
