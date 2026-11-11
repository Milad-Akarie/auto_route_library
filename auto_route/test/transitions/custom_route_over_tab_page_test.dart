import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1426
  // Reported on Android since v6: a CustomRoute that slides from the bottom,
  // or fades in, also made the material page underneath zoom, unless the
  // custom route was a fullscreenDialog.
  // Steps: on Android, with material and adaptive default route types, a
  // page in a router inside an AutoTabsRouter.tabBar tab; push a CustomRoute
  // with slideBottom over it from that router, and a non-opaque fadeIn
  // CustomRoute from the root.
  // Should: the page underneath keeps its place and size while the custom
  // page opens and closes.
  for (final (label, type) in [
    ('material', const RouteType.material()),
    ('adaptive', const RouteType.adaptive()),
  ]) {
    for (final (name, nested) in [
      ('AlbumSongsRoute', true),
      ('DialogRoute', false),
    ]) {
      testWidgets('A $label page under $name, a CustomRoute, does not zoom', (
        tester,
      ) async {
        final router = RootStackRouter.build(
          defaultRouteType: type,
          routes: [
            NamedRouteDef(
              name: 'TabsRoute',
              path: '/',
              builder: (_, _) => AutoTabsRouter.tabBar(
                routes: const [NamedRoute('LibraryRoute')],
                builder: (_, child, _) => child,
              ),
              children: [
                NamedRouteDef.shell(
                  name: 'LibraryRoute',
                  path: 'library',
                  children: [
                    NamedRouteDef(
                      name: 'HomeRoute',
                      path: '',
                      builder: (_, _) =>
                          const Scaffold(body: Text('HomeRoute')),
                    ),
                    CustomRoute(
                      page: PageInfo(
                        'AlbumSongsRoute',
                        builder: (_) =>
                            const Scaffold(body: Text('AlbumSongsRoute')),
                      ),
                      path: 'album',
                      transitionsBuilder: TransitionsBuilders.slideBottom,
                      duration: const Duration(milliseconds: 200),
                      reverseDuration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ],
            ),
            CustomRoute(
              page: PageInfo(
                'DialogRoute',
                builder: (_) => const Center(child: Text('DialogRoute')),
              ),
              path: '/dialog',
              opaque: false,
              transitionsBuilder: TransitionsBuilders.fadeIn,
              duration: const Duration(milliseconds: 300),
              reverseDuration: const Duration(milliseconds: 300),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: ThemeData(platform: .android),
            routerConfig: router.config(),
          ),
        );
        await tester.pumpAndSettle();
        final resting = tester.getRect(find.text('HomeRoute'));
        final scope = nested
            ? tester.element(find.text('HomeRoute')).router
            : router;

        Future<void> expectHomeInPlaceHalfway() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.getRect(find.text('HomeRoute')), resting);
          await tester.pumpAndSettle();
        }

        unawaited(scope.push(NamedRoute(name)));
        await expectHomeInPlaceHalfway();
        expect(find.text(name), findsOneWidget);
        scope.pop();
        await expectHomeInPlaceHalfway();
        expect(find.text(name), findsNothing);
      });
    }
  }
}
