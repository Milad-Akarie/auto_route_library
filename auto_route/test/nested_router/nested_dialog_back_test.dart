import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#113459: with a shell route, the device's back button popped
// the page behind an open dialog and left the dialog open.
// Steps: a host page with a nested router; open 'settings' in it, then a
// dialog from the settings page (on the root navigator, and on the nested
// one), then press back.
// Should: back closes the dialog; the settings page stays; a second back
// pops the settings page.
void main() {
  for (final useRootNavigator in [true, false]) {
    testWidgets('System back closes a dialog opened with useRootNavigator: '
        '$useRootNavigator first', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'ShellRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const AutoRouter(),
            children: [
              NamedRouteDef(
                name: 'HomeRoute',
                path: 'home',
                initial: true,
                builder: (_, _) => const Text('home'),
              ),
              NamedRouteDef(
                name: 'SettingsRoute',
                path: 'settings',
                builder: (context, _) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    useRootNavigator: useRootNavigator,
                    builder: (_) => const AlertDialog(content: Text('dialog')),
                  ),
                  child: const Text('settings'),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const NamedRoute('SettingsRoute')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('settings'));
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(find.text('settings'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  }
}
