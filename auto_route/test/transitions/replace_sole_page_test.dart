import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // flutter/flutter#118254: a Navigator whose sole page was replaced by a
  // page of the same Page class with no key showed no transition, unlike a
  // MaterialPage. Flutter updates a page of the same class and key in place,
  // and auto_route gives every page a key from its route, so a page of
  // another route is a new route.
  // Steps: open A, alone in the stack, then replace() it with B, which slides
  // up over 400 ms; check it every 50 ms.
  // Should: B is part way in at seven of those checks, and A is gone once B
  // settles.
  testWidgets('Replacing the sole page with another route animates', (
    tester,
  ) async {
    CustomRoute sliding(String name, String path) => .new(
      page: PageInfo(name, builder: (_) => Scaffold(body: Text(name))),
      path: path,
      transitionsBuilder: TransitionsBuilders.slideBottom,
      duration: const Duration(milliseconds: 400),
    );
    final router = RootStackRouter.build(
      routes: [sliding('A', '/'), sliding('B', '/b')],
    );
    await pumpRouterApp(tester, router);

    unawaited(router.replace(const NamedRoute('B')));
    // How far B has come in at each frame once it is there.
    final steps = <double>[];
    final b = find.text('B', skipOffstage: false);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (b.evaluate().isNotEmpty) {
        steps.add(ModalRoute.of(tester.element(b))!.animation!.value);
      }
    }
    await tester.pumpAndSettle();
    expect(
      (
        steps.where((step) => step > 0 && step < 1).length,
        steps.lastOrNull,
        find.text('A').evaluate().length,
        router.stack.length,
      ),
      (7, 1.0, 0, 1),
    );
  });

  // flutter/flutter#75973: a page that slid in over a splash page showed
  // almost no slide when it held a TextField. The reporter's app: a splash
  // page replaces itself after a delay with a page that slides in from the
  // right and holds a TextField.
  // Steps: open the splash page, wait 2 seconds, replace it with the page
  // that holds the TextField, and check that page half way through its
  // 300 ms slide.
  // Should: the page is half way in from the right, then settles at 0.
  testWidgets('A page with a TextField slides in over a replaced splash page', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'SplashRoute',
            builder: (_) => const Scaffold(body: Text('splash')),
          ),
        ),
        CustomRoute(
          path: '/verify',
          page: PageInfo(
            'VerifyRoute',
            builder: (_) => const Scaffold(body: TextField()),
          ),
          transitionsBuilder: TransitionsBuilders.slideLeft,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final width = tester.getSize(find.byType(Scaffold)).width;

    await tester.pump(const Duration(seconds: 2));
    unawaited(router.replacePath('/verify'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final halfWay = tester.getTopLeft(find.byType(TextField)).dx;
    await tester.pumpAndSettle();
    expect(
      (
        halfWay,
        tester.getTopLeft(find.byType(TextField)).dx,
        router.current.name,
      ),
      (width / 2, 0, 'VerifyRoute'),
    );
  });

  // flutter/flutter#78983: the offset of a widget, read in a post-frame
  // callback after popping the only page and pushing another by name,
  // differed by route class. That frame is the first of the new page's
  // transition, so the offset is where each class's transition starts. Once
  // the transition settles, it is the same for every class.
  // Steps: open a page alone in the stack, replace it with a page of the
  // given route type that holds a box, and let it settle.
  // Should: the box is where it is when that page is opened directly.
  group(
    'A widget on a page that replaced the sole page (flutter/flutter#78983)',
    () {
      final types = {
        'material': const RouteType.material(),
        'cupertino': const RouteType.cupertino(),
        'custom': RouteType.custom(
          transitionsBuilder: TransitionsBuilders.slideLeft,
        ),
      };
      for (final MapEntry(key: name, value: type) in types.entries) {
        testWidgets('settles in place, $name route', (tester) async {
          RootStackRouter router() => .build(
            defaultRouteType: type,
            routes: [
              AutoRoute(
                path: '/',
                page: PageInfo('HomeRoute', builder: (_) => const Text('home')),
              ),
              AutoRoute(
                path: '/box',
                page: PageInfo(
                  'BoxRoute',
                  builder: (_) => const Scaffold(
                    body: Center(child: SizedBox(key: Key('box'), width: 40)),
                  ),
                ),
              ),
            ],
          );
          await pumpRouterApp(tester, router(), initialLink: '/box');
          final direct = tester.getTopLeft(find.byKey(const Key('box')));
          // A new app, not a new router in the same one.
          await tester.pumpWidget(const SizedBox());

          final replaced = router();
          await pumpRouterApp(tester, replaced);
          unawaited(replaced.replace(const NamedRoute('BoxRoute')));
          await tester.pumpAndSettle();
          expect(
            (
              tester.getTopLeft(find.byKey(const Key('box'))),
              replaced.stack.length,
            ),
            (direct, 1),
          );
        });
      }
    },
  );
}
