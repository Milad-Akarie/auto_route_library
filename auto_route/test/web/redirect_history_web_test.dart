@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/2331
  // The app opens on HomeRoute, whose guard calls
  // redirectUntil(LoginRoute(next: resolver.next)), and LoginRoute calls next()
  // after its first frame.
  // The back button must not reopen LoginRoute with a resolver that was already
  // used. The phone history kept LoginRoute's entry; the browser history never
  // goes back past the app's first entry, so on web this only guards that.
  testWidgets(
    'The browser back button after a resolved redirect on web stays on the guarded page (#2331)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            guards: [
              AutoRouteGuard.simple((resolver, _) {
                unawaited(
                  resolver.redirectUntil(
                    NamedRoute('LoginRoute', args: resolver.next),
                  ),
                );
              }),
            ],
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/login',
            builder: (_, data) {
              final next = data.args! as VoidCallback;
              WidgetsBinding.instance.addPostFrameCallback((_) => next());
              return const Scaffold(body: Text('LoginRoute'));
            },
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
      expect(browserPath, '/');
      final entry = browserSerialCount;

      await pressBrowserBack(tester);
      expect(browserSerialCount, entry);
      expect(browserPath, '/', reason: 'after pressBrowserBack(tester)');
      expect(router.stack.map((e) => e.routeData.name), [
        'HomeRoute',
      ], reason: 'after pressBrowserBack(tester)');
    },
  );

  // flutter/flutter#135359: after a guard's redirect to the login page, the
  // browser's back button did nothing: each press came back to the login page.
  // Logged in, push Screen3, whose guard redirects to SignInRoute when logged
  // out, with reevaluateListenable set to the login state. Log out: the guard
  // redirects to SignInRoute. Press the browser's back button: HomeRoute shows,
  // and each later press steps back through the history, never staying on the
  // entry it was on.
  testWidgets('The browser back button after a logout redirect steps back', (
    tester,
  ) async {
    final loggedIn = ValueNotifier(true);
    addTearDown(loggedIn.dispose);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'Screen3Route',
          path: '/screen3',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              if (loggedIn.value) {
                resolver.next();
              } else {
                unawaited(
                  resolver.redirectUntil(const NamedRoute('SignInRoute')),
                );
              }
            }),
          ],
          builder: (_, _) => const Scaffold(body: Text('Screen3Route')),
        ),
        NamedRouteDef(
          name: 'SignInRoute',
          path: '/signin',
          builder: (_, _) => const Scaffold(body: Text('SignInRoute')),
        ),
      ],
    );
    await pumpRouterConfigApp(
      tester,
      router.config(reevaluateListenable: loggedIn),
    );
    await settleBrowser(tester);
    final start = browserSerialCount;
    unawaited(router.push(const NamedRoute('Screen3Route')));
    await settleBrowser(tester);
    expect(browserPath, '/screen3');

    loggedIn.value = false;
    await settleBrowser(tester);
    expect(router.topRoute.name, 'SignInRoute');
    expect(browserSerialCount, start + 2);

    // The first press closes the sign-in page and with it Screen3, which the
    // logged-out user can't see, as the app's own back button does.
    await pressBrowserBack(tester);
    expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
    expect(browserPath, '/');
    expect(browserSerialCount, start + 1);

    for (var i = 0; i < 3 && browserSerialCount > start; i++) {
      await _pressBackAndExpectFewerEntries(tester);
    }
    expect(tester.takeException(), isNull);
  });

  // The same with the sign-in page closed by the app's own back button, then
  // the browser's back button pressed.
  testWidgets(
    'The browser back button after closing a logout redirect in the app steps back',
    (tester) async {
      final loggedIn = ValueNotifier(true);
      addTearDown(loggedIn.dispose);
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'Screen3Route',
            path: '/screen3',
            guards: [
              AutoRouteGuard.simple((resolver, _) {
                if (loggedIn.value) {
                  resolver.next();
                } else {
                  unawaited(
                    resolver.redirectUntil(const NamedRoute('SignInRoute')),
                  );
                }
              }),
            ],
            builder: (_, _) => const Scaffold(body: Text('Screen3Route')),
          ),
          NamedRouteDef(
            name: 'SignInRoute',
            path: '/signin',
            builder: (_, _) => const Scaffold(body: Text('SignInRoute')),
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(reevaluateListenable: loggedIn),
      );
      await settleBrowser(tester);
      final start = browserSerialCount;
      unawaited(router.push(const NamedRoute('Screen3Route')));
      await settleBrowser(tester);
      expect(browserPath, '/screen3');

      loggedIn.value = false;
      await settleBrowser(tester);
      expect(router.topRoute.name, 'SignInRoute');
      expect(browserSerialCount, start + 2);

      await router.maybePop();
      await settleBrowser(tester);
      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
      expect(browserPath, '/');
      expect(browserSerialCount, start + 1);

      for (var i = 0; i < 3 && browserSerialCount > start; i++) {
        await _pressBackAndExpectFewerEntries(tester);
      }
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pressBackAndExpectFewerEntries(WidgetTester tester) async {
  final before = browserSerialCount;
  await pressBrowserBack(tester);
  expect(browserSerialCount, lessThan(before));
}
