import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

Widget _page(String name) => Scaffold(body: Center(child: Text(name)));

void main() {
  // https://github.com/flutter/flutter/issues/100682
  // The reporter pushed a sign-in route from a page below another route, and
  // it behaved as go() did: the pages under it were gone, so popping did not
  // return. Steps: open '/settings/profile', push SignInRoute with a query
  // param on the root router, then pop. The sign-in page shows above the
  // settings page, and pop returns to '/settings/profile'.
  testWidgets('push() of a root route from a nested page keeps the pages under it (flutter/flutter#100682)', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => _page('HomeRoute')),
        NamedRouteDef(
          name: 'SettingsRoute',
          path: '/settings',
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(name: 'SettingsHomeRoute', path: '', builder: (_, _) => _page('SettingsHomeRoute')),
            NamedRouteDef(name: 'ProfileRoute', path: 'profile', builder: (_, _) => _page('ProfileRoute')),
          ],
        ),
        NamedRouteDef(name: 'SignInRoute', path: '/sign-in', builder: (_, _) => _page('SignInRoute')),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/settings/profile');
    expect(router.urlState.url, '/settings/profile');

    unawaited(router.push(const NamedRoute('SignInRoute', queryParams: {'back': 'true'})));
    await tester.pumpAndSettle();
    expect(router.stack.map((e) => e.name), ['HomeRoute', 'SettingsRoute', 'SignInRoute']);
    expect(router.urlState.url, '/sign-in?back=true');

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('ProfileRoute'), findsOneWidget);
    expect(router.urlState.url, '/settings/profile');
  });
}
