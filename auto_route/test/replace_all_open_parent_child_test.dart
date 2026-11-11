import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/1586
// Reported on version 7.3: replaceAll with a parent that is already open and
// an explicit child showed the parent's default child, which version 7.4.0
// fixed with updateExistingRoutes. Listing the child after the parent didn't
// work either.
// Setup: the root route MainRoute has the children HomeRoute, which its empty
// path redirects to, and SearchRoute. InfoRoute is a second root route. The
// app starts on MainRoute and HomeRoute.
// Steps: replaceAll with MainRoute holding SearchRoute as its child, with the
// default and with updateExistingRoutes false. Then, from a fresh start,
// replaceAll listing MainRoute and SearchRoute, the reporter's second form.
// Reported, second form: it did not work. Before this fix it failed Flutter's
// assertion about two pages with one key, as the new parent's children were
// opened twice in the nested router it took over.
// Should: SearchRoute is the shown page in all of them; the second form keeps
// MainRoute's default child below it.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        initial: true,
        page: PageInfo('MainRoute', builder: (_) => const AutoRouter()),
        children: [
          RedirectRoute(path: '', redirectTo: 'home'),
          AutoRoute(path: 'home', page: _page('HomeRoute')),
          AutoRoute(path: 'search', page: _page('SearchRoute')),
        ],
      ),
      AutoRoute(path: '/info', page: _page('InfoRoute')),
      RedirectRoute(path: '*', redirectTo: '/'),
    ],
  );

  const mainWithSearch = NamedRoute(
    'MainRoute',
    children: [NamedRoute('SearchRoute')],
  );

  for (final updateExistingRoutes in [true, false]) {
    testWidgets(
      'replaceAll with an open parent and a Search child shows Search '
      '(updateExistingRoutes: $updateExistingRoutes)',
      (tester) async {
        final router = buildRouter();
        await pumpRouterApp(tester, router);
        expectTopPage(router, 'HomeRoute');

        unawaited(
          router.replaceAll([
            mainWithSearch,
          ], updateExistingRoutes: updateExistingRoutes),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expectTopPage(router, 'SearchRoute');
        expect(router.stack.map((page) => page.name), ['MainRoute']);
      },
    );
  }

  testWidgets('replaceAll with MainRoute and then SearchRoute shows Search', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);

    unawaited(
      router.replaceAll([
        const NamedRoute('MainRoute'),
        const NamedRoute('SearchRoute'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expectTopPage(router, 'SearchRoute');
    expect(router.stack.map((page) => page.name), ['MainRoute']);
    expect(
      router.innerRouterOf<StackRouter>('MainRoute')!.stack.map((p) => p.name),
      ['HomeRoute', 'SearchRoute'],
      reason: "MainRoute's default child, then the listed one",
    );
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
