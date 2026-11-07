import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/amizone_service.dart';

/// Shows Amizone's own login page so the student can pass the Cloudflare
/// check that guards it, then hands the authenticated session cookies back.
///
/// The portal also has a long-standing bug where its inline `validateToken`
/// calls `getElementById("loginForm")` while the form id is `loginform`, so the
/// Login button throws instead of submitting. We patch that here and submit the
/// real form once Cloudflare has issued its token.
class AmizoneWebLoginScreen extends StatefulWidget {
  const AmizoneWebLoginScreen({
    super.key,
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  State<AmizoneWebLoginScreen> createState() => _AmizoneWebLoginScreenState();
}

class _AmizoneWebLoginScreenState extends State<AmizoneWebLoginScreen> {
  double _progress = 0;
  bool _finished = false;
  bool _prefilled = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          'Verify with Amizone',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              _error ??
                  'Enter your Amizone credentials, complete the verification, '
                      'then tap Login. CampusTrack continues automatically.',
              style: TextStyle(fontSize: 12, color: Colors.indigo.shade900),
            ),
          ),
          if (_progress < 1)
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(AmizoneService.portalUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                thirdPartyCookiesEnabled: true,
                sharedCookiesEnabled: true,
                useShouldOverrideUrlLoading: false,
              ),
              onProgressChanged: (controller, progress) {
                if (mounted) setState(() => _progress = progress / 100);
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame == true && mounted) {
                  setState(() => _error = 'Amizone could not be loaded: ${error.description}');
                }
              },
              onLoadStop: (controller, url) => _onLoadStop(controller, url),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    if (_finished) return;

    final shouldPrefillPassword = !_prefilled;
    final state = await controller.evaluateJavascript(
      source: """
        (function () {
          var form = document.querySelector('#loginform');
          if (!form) return 'app';

          var user = form.querySelector('input[name="_UserName"]');
          if (user && !user.value) {
            user.value = ${jsonEncode(widget.username)};
            user.dispatchEvent(new Event('input', { bubbles: true }));
          }
          var pass = form.querySelector('input[name="_Password"]');
          if (pass && !pass.value && $shouldPrefillPassword) {
            pass.value = ${jsonEncode(widget.password)};
            pass.dispatchEvent(new Event('input', { bubbles: true }));
          }
          var q = form.querySelector('input[name="_QString"]');
          if (q && !q.value) q.value = 'test';

          // The portal's own submit handler throws on getElementById('loginForm')
          // (the form id is lowercase), so submit the real form ourselves once
          // Cloudflare has issued its token.
          if (!window.__campusTrackSubmit) {
            window.__campusTrackSubmit = true;
            document.addEventListener('click', function (event) {
              var button = event.target && event.target.closest
                  ? event.target.closest('button[type="submit"]')
                  : null;
              if (!button) return;
              var loginForm = document.getElementById('loginform');
              if (!loginForm || loginForm.contains(button) === false) return;
              var captcha = loginForm.querySelector('input[name="cf-turnstile-response"]');
              if (!captcha || !captcha.value) return;
              var token = loginForm.querySelector('input[name="RecaptchaToken"]');
              if (token && !token.value) token.value = captcha.value;
              event.preventDefault();
              event.stopImmediatePropagation();
              loginForm.submit();
            }, true);
          }

          return document.body.innerText.indexOf('Please check your credential') !== -1
            ? 'login:rejected'
            : 'login';
        })();
      """,
    );

    _prefilled = true;
    final result = state.toString();
    debugPrint('Amizone WebView: state=$result url=$url');
    if (result.contains('app')) {
      // Authenticated: fall through and harvest the session.
    } else {
      if (result.contains('rejected') && mounted) {
        setState(() {
          _error = 'Amizone did not accept that sign-in. Check the username and '
              'password in the page, then tap LOGIN again.';
        });
      }
      return;
    }

    // Give the WebView a moment to commit the session cookies.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || _finished) return;

    try {
      final cookies = await CookieManager.instance().getCookies(
        url: WebUri(AmizoneService.portalUrl),
      );
      final session = <String, String>{
        for (final cookie in cookies)
          if (cookie.name.isNotEmpty) cookie.name: cookie.value,
      };
      // Names only: the values are the live session tokens.
      debugPrint('Amizone WebView: harvested ${session.length} cookies '
          '(${session.keys.join(", ")})');
      if (session.isEmpty) {
        setState(() => _error = 'Amizone did not return a session. Please try again.');
        return;
      }
      _finished = true;
      if (mounted) Navigator.of(context).pop(session);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not read the Amizone session: $error');
      }
    }
  }
}
