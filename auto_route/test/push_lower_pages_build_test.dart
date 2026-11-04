import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'build_counts.dart';
import 'router_test_utils.dart';

void main() {
  late BuildCounts builds;

  setUp(() => builds = {});

  // flutter/flutter#132049, flutter/flutter#137413, flutter/flutter#138708 and
  // flutter/flutter#144511: in go_router, pushing a page built the widgets of
  // the pages under it again when they were not const, though they were
  // covered. auto_route keeps each page's Page object, so the Navigator has
  // no reason to build a covered page again.
  // Steps: open Home, push A, then B, then C with router.push; every page's
  // widget is not const.
  // Should: each page builds once; the pages under the new one don't build.
  testWidgets('Pushing pages does not build the pages under them again', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: countedPage('Home', builds), path: '/'),
        for (final name in ['A', 'B', 'C']) AutoRoute(page: countedPage(name, builds), path: '/${name.toLowerCase()}'),
      ],
    );
    await pumpRouterApp(tester, router);
    for (final name in ['A', 'B', 'C']) {
      unawaited(router.push(NamedRoute(name)));
      await tester.pumpAndSettle();
      expectTopPage(router, name);
    }

    expect(builds, {'Home': 1, 'A': 1, 'B': 1, 'C': 1});
  });

  // flutter/flutter#137413 with sub-routes: Details hosts a nested router and
  // Child is pushed in it.
  // Steps: open Home, push Details, then push Child inside Details.
  // Should: Home and Details build once each.
  testWidgets('Pushing a page in a nested router does not build its host again', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: countedPage('Home', builds), path: '/'),
        AutoRoute(
          page: countedPage('Details', builds, body: const AutoRouter()),
          path: '/details',
          children: [
            AutoRoute(page: countedPage('Overview', builds), path: ''),
            AutoRoute(page: countedPage('Child', builds), path: 'child'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('Details')));
    await tester.pumpAndSettle();
    final detailsRouter = router.innerRouterOf<StackRouter>('Details')!;
    unawaited(detailsRouter.push(const NamedRoute('Child')));
    await tester.pumpAndSettle();
    expectTopPage(detailsRouter, 'Child');

    expect(builds, {'Home': 1, 'Details': 1, 'Overview': 1, 'Child': 1});
  });
}
