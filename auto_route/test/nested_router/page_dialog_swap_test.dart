import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/170533
  // Reported for go_router on macOS: settings open as a dialog on a wide
  // window and as a page on a narrow one, each with its own nested router.
  // The app swapped one for the other as the window was resized; resizing
  // back and forth before the swap's animation ended asserted
  // "'route._navigator == navigator': is not true".
  // Steps: open the settings dialog at its account page, then swap it for
  // the settings page and back four times, 50 ms apart, each time at the
  // account page, as the resize handler does.
  // Should: no error, and the last swap shows the account page in the
  // dialog.
  // On web, a replace made while the page it replaces was still animating
  // out also asserted "Both Router.navigate and Router.neglect have been
  // called in this build cycle", and outside debug builds added a browser
  // entry instead of replacing one. The url of the new page was read from the
  // outgoing page's nested router, which has the same route key; the new
  // page's own nested router then reported a page with another id at the
  // same url, taken for a page pushed over it.
  testWidgets(
    'Swapping a dialog and a page, each with a nested router, mid-animation '
    'throws nothing',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Text('HomeRoute'),
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
      await pumpRouterApp(tester, router);
      router.push(_settings('DialogSettingsRoute', 'dialogAccount')).ignore();
      await tester.pumpAndSettle();
      final dialogAccountShown = find.text('dialog account').evaluate().length;

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

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'DialogSettingsRoute',
      ]);
      expect(
        (dialogAccountShown, find.text('dialog account').evaluate().length),
        (1, 1),
      );
    },
  );
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
