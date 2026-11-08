import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/amizone_service.dart';

/// Opens the list of Amizone accounts saved on this device.
Future<void> showAccountSwitcher(BuildContext context) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return AnimatedBuilder(
        animation: AmizoneService.instance,
        builder: (context, _) {
          final amizone = AmizoneService.instance;
          final accounts = amizone.accounts;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'User Accounts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${accounts.length} saved',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to switch user instantly without password.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 14),
                  if (accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No saved accounts yet.',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    )
                  else
                    ...accounts.map((account) {
                      final current = amizone.isCurrent(account.username);
                      final initial = account.username.trim().isEmpty
                          ? '?'
                          : account.username.trim().substring(0, 1).toUpperCase();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: current
                              ? theme.colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: current
                                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                                : theme.dividerColor,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: CircleAvatar(
                            backgroundColor: current
                                ? const Color(0xFF1E3A8A)
                                : theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: current ? Colors.white : theme.colorScheme.primary,
                            child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(
                            account.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            !account.hasSession
                                ? 'Session expired • Tap to re-login'
                                : current
                                    ? 'Current active user (${account.courses.length} subjects)'
                                    : 'Tap to switch (${account.courses.length} subjects)',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: current
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : IconButton(
                                  tooltip: 'Remove',
                                  icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                  onPressed: () async {
                                    await amizone.removeAccount(account.username);
                                  },
                                ),
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            if (!account.hasSession) {
                              await openAccountLogin(context, username: account.username);
                              return;
                            }
                            if (!current) await amizone.switchTo(account.username);
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      openAccountLogin(context);
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Add New Account (With Password)'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Pushes the sign-in screen. [username] prefills an enrollment number.
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
