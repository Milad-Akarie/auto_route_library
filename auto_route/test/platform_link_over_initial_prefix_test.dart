import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';
import 'universal_link_test.dart' show didSendPlatformLink;

// https://github.com/Milad-Akarie/auto_route_library/issues/2167
// Setup: routes '/login' and an initial '/' that holds a nested 'discussions'
// page; `config(includePrefixMatches: false)` and no deepLinkBuilder.
// Steps: start the app the way Flutter does on a cold start from a link, with
// the first route '/', then the platform sends the link '/login'.
// Reported: the stack was [main with discussions, login]; the maintainer saw
// the deep link builder called first with '/' and then with '/login'.
// Should: the stack holds only the login page, as the link names no parent. A
// link that reaches an app that has been in the background opens over its page,
// as any link does in a running app. On the web the browser opens the app at
// its url, so no route comes after the first one this way, and those tests are
// skipped there.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: _page('LoginRoute'), path: '/login'),
      AutoRoute(
        page: _page('MainRoute', isShell: true),
        path: '/',
        initial: true,
        children: [
          AutoRoute(
            page: _page('DiscussionsRoute'),
            path: 'discussions',
            initial: true,
          ),
        ],
      ),
    ],
  );

  testWidgets(
    'A platform link after the first route keeps no home page below it when '
    'includePrefixMatches is false',
    (tester) async {
      final router = buildRouter();
      await pumpRouterConfigApp(
        tester,
        router.config(includePrefixMatches: false),
      );
      expect(find.text('DiscussionsRoute'), findsOneWidget);

      await didSendPlatformLink(tester, '/login');
      expect(find.text('LoginRoute'), findsOneWidget);
      expect(router.stack.map((page) => page.name), ['LoginRoute']);
    },
    skip: kIsWeb,
  );

  testWidgets(
    'A platform link a guard rejects after the first route keeps the home page',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _page('MainRoute'), path: '/', initial: true),
          AutoRoute(
            page: _page('SecretRoute'),
            path: '/secret',
            guards: [AutoRouteGuard.simple((resolver, _) => resolver.reject())],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(includePrefixMatches: false),
      );

      await didSendPlatformLink(tester, '/secret');
      expect(find.text('MainRoute'), findsOneWidget);
      expect(router.stack.map((page) => page.name), ['MainRoute']);
    },
  );

  testWidgets(
    'A platform link keeps the home page below it after the app was in the '
    'background',
    (tester) async {
      final router = buildRouter();
      tester.binding.handleAppLifecycleStateChanged(.resumed);
      await pumpRouterConfigApp(
        tester,
        router.config(includePrefixMatches: false),
      );
      const toBackgroundAndBack = <AppLifecycleState>[
        .inactive,
        .hidden,
        .inactive,
        .resumed,
      ];
      toBackgroundAndBack.forEach(
        tester.binding.handleAppLifecycleStateChanged,
      );

      await didSendPlatformLink(tester, '/login');
      expect(router.stack.map((page) => page.name), [
        'MainRoute',
        'LoginRoute',
      ]);
    },
  );

  testWidgets('A platform link keeps the home page below it when '
      'includePrefixMatches is true', (tester) async {
    final router = buildRouter();
    await pumpRouterConfigApp(
      tester,
      router.config(includePrefixMatches: true),
    );

    await didSendPlatformLink(tester, '/login');
    expect(router.stack.map((page) => page.name), ['MainRoute', 'LoginRoute']);
  });

  testWidgets('A second platform link opens over the first', (tester) async {
    final router = buildRouter();
    await pumpRouterConfigApp(
      tester,
      router.config(includePrefixMatches: false),
    );

    await didSendPlatformLink(tester, '/login');
    await didSendPlatformLink(tester, '/');
    expect(router.stack.map((page) => page.name), ['LoginRoute', 'MainRoute']);
  }, skip: kIsWeb);

  testWidgets('A platform link to the launch page leaves it in place', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterConfigApp(
      tester,
      router.config(includePrefixMatches: false),
    );

    await didSendPlatformLink(tester, '/');
    expect(find.text('DiscussionsRoute'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['MainRoute']);
  });

  testWidgets('A cold start at the link keeps no home page below it when '
      'includePrefixMatches is false', (tester) async {
    final router = buildRouter();
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/login';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await pumpRouterConfigApp(
      tester,
      router.config(includePrefixMatches: false),
    );
    expect(router.stack.map((page) => page.name), ['LoginRoute']);
  });
}

PageInfo _page(String name, {bool isShell = false}) => .new(
  name,
  builder: (_) =>
      isShell ? const Scaffold(body: AutoRouter()) : Scaffold(body: Text(name)),
);
