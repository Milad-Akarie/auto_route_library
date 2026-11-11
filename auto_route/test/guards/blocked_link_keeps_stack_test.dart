import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

// flutter/flutter#178853: when onEnter blocked a link, go_router restored a
// stale stack. Here a guard stops a link that arrives while the app has
// pages open, by path and by route.
// Steps: open Home, push Details, then navigate to /protected, a route whose
// guard rejects, with navigatePath, pushPath and navigate.
// Should: the stack stays [Home, Details] and Details stays on screen.
void main() {
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('HomeRoute'), path: '/'),
        AutoRoute(page: _page('DetailsRoute'), path: '/details'),
        AutoRoute(
          page: _page('ProtectedRoute'),
          path: '/protected',
          guards: [AutoRouteGuard.simple((resolver, _) => resolver.reject())],
        ),
      ],
    );
  });

  final links = <String, Future<Object?> Function(RootStackRouter router)>{
    'navigatePath': (activeRouter) => activeRouter.navigatePath('/protected'),
    'pushPath': (activeRouter) => activeRouter.pushPath('/protected'),
    'navigate': (activeRouter) =>
        activeRouter.navigate(const NamedRoute('ProtectedRoute')),
  };

  for (final MapEntry(:key, :value) in links.entries) {
    testWidgets(
      'A link blocked by a guard with $key leaves the stack as it was (flutter/flutter#178853)',
      (tester) async {
        await pumpRouterApp(tester, router);
        unawaited(router.push(const NamedRoute('DetailsRoute')));
        await tester.pumpAndSettle();

        unawaited(value(router));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(router.stack.map((p) => p.name), ['HomeRoute', 'DetailsRoute']);
        expect(find.text('DetailsRoute'), findsOneWidget);
      },
    );
  }
}
