import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The page under a CustomRoute that slides in from the top stays in place.
// https://github.com/Milad-Akarie/auto_route_library/issues/1881
// Headless test: auto_route/test/transitions/custom_route_underneath_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open a first page, with the platform's adaptive route type, push
  // a CustomRoute whose builder is slideTop, then close it.
  // Should: the first page does not move while the custom page opens or closes.
  testWidgets('A page stays in place under a CustomRoute that slides from the top', (tester) async {
    final router = RootStackRouter.build(
      defaultRouteType: const RouteType.adaptive(),
      routes: [
        AutoRoute(page: _page('Home'), path: '/'),
        CustomRoute(page: _page('Menu'), path: '/menu', transitionsBuilder: TransitionsBuilders.slideTop),
      ],
    );
    await pumpRouterApp(tester, router);
    final restingX = tester.getTopLeft(find.text('Home')).dx;

    Future<void> expectHomeInPlaceHalfway(void Function() action) async {
      action();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getTopLeft(find.text('Home')).dx, restingX);
      await tester.pumpAndSettle();
    }

    await expectHomeInPlaceHalfway(() => unawaited(router.push(const PageRouteInfo('Menu'))));
    expect(find.text('Menu'), findsOneWidget);
    await expectHomeInPlaceHalfway(() => unawaited(router.maybePop()));
    expect(find.text('Menu'), findsNothing);
  });
}

PageInfo _page(String name) => PageInfo(
  name,
  builder: (_) => Scaffold(
    body: Align(alignment: Alignment.topLeft, child: Text(name)),
  ),
);
