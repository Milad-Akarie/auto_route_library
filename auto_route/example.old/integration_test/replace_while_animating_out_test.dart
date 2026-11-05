import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A replace made while the page it replaces is still animating out, found
// while guarding https://github.com/flutter/flutter/issues/170533.
// Headless test: auto_route/test/nested_router/page_dialog_swap_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the settings dialog at its account page, then replace it with
  // the settings page and back four times, 50 ms apart, each at the account
  // page, so each replace comes while the page before is still animating out.
  // Should: no error, the dialog's account page on top, and on web the
  // browser shows its url in the entry the dialog had: each replace replaces
  // the entry instead of adding one.
  testWidgets('Replacing a page while it animates out replaces its url', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'SettingsRoute',
          path: '/settings',
          builder: (_, _) => const Scaffold(body: AutoRouter()),
          children: _settingsChildren('page'),
        ),
        CustomRoute(
          path: '/dialog_settings',
          page: PageInfo(
            'DialogSettingsRoute',
            builder: (_) => const Dialog(
              child: SizedBox(width: 300, height: 300, child: AutoRouter()),
            ),
          ),
          customRouteBuilder: <T>(context, child, page) => DialogRoute<T>(
            context: context,
            settings: page,
            builder: (_) => child,
          ),
          children: _settingsChildren('dialog'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpRouterApp(tester, router);
    router.push(_settings('DialogSettingsRoute', 'dialogAccount')).ignore();
    await tester.pumpAndSettle();
    await expectBrowserUrl('/dialog_settings/account');
    final dialogEntry = browserEntryIndex();

    for (final (route, account) in [
      ('SettingsRoute', 'pageAccount'),
      ('DialogSettingsRoute', 'dialogAccount'),
      ('SettingsRoute', 'pageAccount'),
      ('DialogSettingsRoute', 'dialogAccount'),
    ]) {
      router.replace(_settings(route, account)).ignore();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    // The engine answers once it has written every route reported before.
    if (kIsWeb) await SystemNavigator.selectMultiEntryHistory();

    expect(tester.takeException(), isNull);
    expect(router.stack.map((page) => page.name), [
      'HomeRoute',
      'DialogSettingsRoute',
    ]);
    expect(find.text('dialog account'), findsOneWidget);
    await expectBrowserUrl('/dialog_settings/account');
    expect(browserEntryIndex(), dialogEntry, reason: 'the browser entry');
  });
}

PageRouteInfo<void> _settings(String route, String account) =>
    NamedRoute(route, children: [NamedRoute(account)]);

List<AutoRoute> _settingsChildren(String kind) => [
  NamedRouteDef(
    name: '${kind}General',
    path: '',
    builder: (_, _) => Text('$kind general'),
  ),
  NamedRouteDef(
    name: '${kind}Account',
    path: 'account',
    builder: (_, _) => Text('$kind account'),
  ),
];
