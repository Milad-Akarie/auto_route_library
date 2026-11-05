import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'named_page.dart';
import 'router_test_utils.dart';

// flutter/flutter#115832, #115913, #116769, #117431 and #117671: go_router
// reported a stale url, or one with a trailing slash, after a pop, and a
// location that lagged behind a jump of more than two levels.
// Setup: a flat stack '/', '/a', '/a/details', and a nested tree
// '/one' > 'two' > 'three'.
// Steps: open the deepest page in one jump, pop back step by step through
// maybePop and through Navigator.pop.
// Should: the router's url is the visible page's url at every step, without
// a trailing slash.
RootStackRouter _router() => .build(
  routes: [
    NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => const NamedPage('HomeRoute')),
    NamedRouteDef(name: 'ARoute', path: '/a', builder: (_, _) => const NamedPage('ARoute')),
    NamedRouteDef(name: 'DetailsRoute', path: '/a/details', builder: (_, _) => const NamedPage('DetailsRoute')),
    NamedRouteDef(
      name: 'OneRoute',
      path: '/one',
      builder: (_, _) => const AutoRouter(),
      children: [
        NamedRouteDef(name: 'OneIndexRoute', path: '', builder: (_, _) => const NamedPage('OneIndexRoute')),
        NamedRouteDef(
          name: 'TwoRoute',
          path: 'two',
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(name: 'TwoIndexRoute', path: '', builder: (_, _) => const NamedPage('TwoIndexRoute')),
            NamedRouteDef(name: 'ThreeRoute', path: 'three', builder: (_, _) => const NamedPage('ThreeRoute')),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  testWidgets('maybePop and Navigator.pop from a pushed page report the parent url without a trailing slash', (
    tester,
  ) async {
    final router = _router();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('ARoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/a/details');

    await router.maybePopTop();
    await tester.pumpAndSettle();
    expect(find.text('ARoute'), findsOneWidget);
    expect(router.currentUrl, '/a');

    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('DetailsRoute'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('ARoute'), findsOneWidget);
    expect(router.currentUrl, '/a');
    expect(router.urlState.url, '/a');

    await router.maybePopTop();
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/');
  });

  testWidgets(
    'Opening a page three levels deep in one jump reports its full url, and popping it reports the page under',
    (tester) async {
      final router = _router();
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.navigatePath('/one/two/three'));
      await tester.pumpAndSettle();
      expect(find.text('ThreeRoute'), findsOneWidget);
      expect(router.currentUrl, '/one/two/three');
      expect(router.urlState.url, '/one/two/three');

      await router.maybePopTop();
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(router.currentUrl, '/');
    },
  );

  testWidgets('Popping twice out of a page three levels deep reports /one/two, then the page under', (tester) async {
    final router = _router();
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigatePath('/one/two'));
    await tester.pumpAndSettle();
    final twoRouter = router.innerRouterOf<StackRouter>('OneRoute')!.innerRouterOf<StackRouter>('TwoRoute')!;
    unawaited(twoRouter.push(const NamedRoute('ThreeRoute')));
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/one/two/three');

    await router.maybePopTop();
    await tester.pumpAndSettle();
    expect(find.text('TwoIndexRoute'), findsOneWidget);
    expect(router.currentUrl, '/one/two');

    await router.maybePopTop();
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute'), findsOneWidget);
    expect(router.currentUrl, '/');
  });
}
