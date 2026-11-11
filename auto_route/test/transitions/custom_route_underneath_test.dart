import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1881
  // Reported: a CustomRoute whose page slides in from the top still makes
  // the page underneath slide to the left, so a black area shows beside it,
  // while the new page opens and again while it closes.
  // Setup: a first page, then a CustomRoute with TransitionsBuilders.slideTop.
  // Should: the first page stays where it is while the custom page opens and
  // closes, whichever route type the first page has.
  for (final (label, type, platform) in [
    ('cupertino', const RouteType.cupertino(), TargetPlatform.iOS),
    ('material', const RouteType.material(), TargetPlatform.android),
    ('adaptive on iOS', const RouteType.adaptive(), TargetPlatform.iOS),
    (
      'custom',
      RouteType.custom(transitionsBuilder: TransitionsBuilders.slideLeft),
      TargetPlatform.android,
    ),
  ]) {
    testWidgets(
      'A $label page stays in place under a CustomRoute that slides from the '
      'top',
      (tester) async {
        final router = RootStackRouter.build(
          defaultRouteType: type,
          routes: [
            AutoRoute(page: _page('Home'), path: '/'),
            CustomRoute(
              page: _page('Menu'),
              path: '/menu',
              transitionsBuilder: TransitionsBuilders.slideTop,
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: ThemeData(platform: platform),
            routerConfig: router.config(),
          ),
        );
        await tester.pumpAndSettle();
        final restingX = tester.getTopLeft(find.text('Home')).dx;

        Future<void> expectHomeInPlaceHalfway(VoidCallback action) async {
          action();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 150));
          expect(find.text('Menu'), findsOneWidget);
          expect(
            tester.getTopLeft(find.text('Menu')).dy,
            lessThan(0),
            reason: 'the Menu page should be sliding',
          );
          expect(tester.getTopLeft(find.text('Home')).dx, restingX);
          await tester.pumpAndSettle();
        }

        await expectHomeInPlaceHalfway(
          () => router.push(const PageRouteInfo('Menu')),
        );
        await expectHomeInPlaceHalfway(() => unawaited(router.maybePop()));
      },
    );
  }
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    body: Align(alignment: Alignment.topLeft, child: Text(name)),
  ),
);
