import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'details_args.dart';
import 'router_test_utils.dart';

// #1461: opening Wiredash, which wraps the app and shrinks it, rebuilt the
// open page from the router (pushAllGuarded) and its args came back null.
// A resize alone keeps the stack (resize_keeps_stack_test.dart); a wrapper
// that changes its own widgets also builds MaterialApp.router anew, a new
// Router widget that asks for the route again.
// Steps: push DetailsRoute with an args object; then build MaterialApp.router
// again under another parent, which mounts it anew, with the routerConfig
// kept or made again with router.config(), and shrink the window.
// Should: the stack stays [Home, Details], no new page is built, and Details
// still shows its args.
void main() {
  for (final makesConfigAgain in [false, true]) {
    final configKind = makesConfigAgain ? 'a new config()' : 'the same config';
    testWidgets('an app remounted with $configKind keeps pages and args', (
      tester,
    ) async {
      // Counts the pages built for DetailsRoute.
      var detailsBuilds = 0;
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          NamedRouteDef(
            name: 'DetailsRoute',
            path: '/details',
            builder: (_, data) {
              detailsBuilds++;
              final args = data.argsAs<DetailsArgs>();
              return Scaffold(body: Text('Details ${args.id}'));
            },
          ),
        ],
      );
      final config = router.config();
      await pumpRouterConfigApp(tester, config);
      unawaited(
        router.push(const NamedRoute('DetailsRoute', args: DetailsArgs(id: 7))),
      );
      await tester.pumpAndSettle();
      final buildsBefore = detailsBuilds;
      final pageBefore = router.topPage;

      addTearDown(tester.view.reset);
      tester.view.physicalSize = tester.view.physicalSize * 0.7;
      await tester.pumpWidget(
        Padding(
          padding: const .only(top: 100),
          child: MaterialApp.router(
            routerConfig: makesConfigAgain ? router.config() : config,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), [
        'HomeRoute',
        'DetailsRoute',
      ]);
      expect(router.topPage, same(pageBefore));
      expect(find.text('Details 7'), findsOneWidget);
      expect(detailsBuilds, buildsBefore);
    });
  }
}
