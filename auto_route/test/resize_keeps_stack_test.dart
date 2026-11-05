import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#126909: in go_router, a redirect that read MediaQuery.of
// made the pushed page vanish when the window was resized.
// auto_route's guards get no BuildContext, so the app reads the size in a page
// instead; this pins that a resize leaves the stack, the url and the guards
// alone.
// Steps: push a page above the home page, resize the window.
// Should: the pushed page is still on top, at the same url, and no guard ran again.
void main() {
  testWidgets('Resizing the window keeps the pushed page, its url, and does not run the guards again', (tester) async {
    var guardCalls = 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/', page: _page('HomeRoute')),
        AutoRoute(
          path: '/details',
          guards: [
            AutoRouteGuard.simple((resolver, _) {
              guardCalls++;
              resolver.next();
            }),
          ],
          page: _page('DetailsRoute'),
        ),
      ],
    );
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    expect(guardCalls, 1);

    tester.view.physicalSize = const Size(1000, 700);
    await tester.pumpAndSettle();
    expectTopPage(router, 'DetailsRoute');
    expect(router.currentUrl, '/details');
    expect(router.stack, hasLength(2));
    expect(guardCalls, 1, reason: 'after tester.view.physicalSize = const Size(1000, 700)');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
