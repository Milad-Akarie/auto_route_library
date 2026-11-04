import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../build_counts.dart';

// flutter/flutter#189582: a guard that stopped the app's first navigation
// crashed the app on start, in an assertion.
// Open the app at /protected, whose guard rejects it: the app starts with no
// error, on an empty stack. The same with a guard that rejects and opens
// /fallback instead, with replaceAll or push: the app shows FallbackRoute.
Widget _page(String name) => Scaffold(body: Text(name));

void main() {
  RootStackRouter buildRouter(void Function(NavigationResolver resolver, StackRouter router) onProtected) => .build(
    routes: [
      NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => _page('HomeRoute')),
      NamedRouteDef(
        name: 'ProtectedRoute',
        path: '/protected',
        guards: [AutoRouteGuard.simple(onProtected)],
        builder: (_, _) => _page('ProtectedRoute'),
      ),
      NamedRouteDef(name: 'FallbackRoute', path: '/fallback', builder: (_, _) => _page('FallbackRoute')),
    ],
  );

  testWidgets('A guard rejecting the first navigation starts the app without an error', (tester) async {
    final router = buildRouter((resolver, _) => resolver.reject());
    await pumpAtDeepLink(tester, router, '/protected', includePrefixMatches: false);
    expect(tester.takeException(), isNull);
    expect(router.stack, isEmpty);
    expect(find.text('ProtectedRoute'), findsNothing);
  });

  for (final how in ['replaceAll', 'push']) {
    testWidgets('A guard rejecting the first navigation can open another page with $how', (tester) async {
      final router = buildRouter((resolver, router) {
        resolver.reject();
        const fallback = NamedRoute('FallbackRoute');
        unawaited(how == 'push' ? router.push(fallback) : router.replaceAll([fallback]));
      });
      await pumpAtDeepLink(tester, router, '/protected', includePrefixMatches: false);
      expect(tester.takeException(), isNull);
      expect(router.stack.map((p) => p.name), ['FallbackRoute']);
      expect(find.text('FallbackRoute'), findsOneWidget);
      expect(router.currentUrl, '/fallback');
    });
  }
}
