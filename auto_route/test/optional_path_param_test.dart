import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#106014: go_router_builder force-cast a nullable path param,
// `consoleId!`, to build the location of a route pushed without it, and
// crashed. auto_route reads a nullable `@PathParam() int? consoleId` with
// `pathParams.optInt` and leaves a missing one out of the url. A path
// segment can't be optional (go_router's `:id?`): a link without it doesn't
// match the route.
// The route below is what the generator makes for such a page.
void main() {
  RootStackRouter gamesRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('Home', builder: (_) => const Text('Home')),
      ),
      AutoRoute(
        path: '/retro-games/:consoleId',
        page: PageInfo('Games', builder: (data) => Text('console ${data.inheritedPathParams.optInt('consoleId')}')),
      ),
    ],
  );

  PageRouteInfo gamesRoute([int? consoleId]) => .new('Games', rawPathParams: {'consoleId': consoleId});

  // Steps: push the games route without a console id.
  // Should: no crash; the page opens with a null id, at /retro-games.
  testWidgets('a route pushed without its nullable path param opens', (tester) async {
    final router = gamesRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(gamesRoute()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('console null'), findsOneWidget);
    expect(router.urlState.url, '/retro-games');
  });

  // Steps: push the games route with console id 3, then open /retro-games/4.
  // Should: the page reads 3, then 4.
  testWidgets('the nullable path param is read when given', (tester) async {
    final router = gamesRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(gamesRoute(3)));
    await tester.pumpAndSettle();
    expect(find.text('console 3'), findsOneWidget);
    expect(router.urlState.url, '/retro-games/3');

    unawaited(router.navigatePath('/retro-games/4'));
    await tester.pumpAndSettle();
    expect(find.text('console 4'), findsOneWidget);
  });
}
