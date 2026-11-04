import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/191133
  // In go_router, with the iOS page transition of package:cupertino_ui in the
  // theme, the iOS edge swipe followed the finger but never popped the page:
  // go_router looked for Flutter's own MaterialApp and CupertinoApp, not the
  // ones of material_ui and cupertino_ui.
  // Steps: an iOS app on material_ui's MaterialApp whose theme takes
  // cupertino_ui's CupertinoPageTransitionsBuilder for iOS; push Detail, then
  // swipe from the left edge.
  // Should: the swipe pops Detail and Home shows.
  for (final (label, type) in [
    ('RouteType.material()', const RouteType.material()),
    ('RouteType.cupertino()', const RouteType.cupertino()),
  ]) {
    testWidgets('The iOS edge swipe pops a page of $label under the cupertino_ui transition (flutter/flutter#191133)', (
      tester,
    ) async {
      PageInfo page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
      final router = RootStackRouter.build(
        defaultRouteType: type,
        routes: [
          AutoRoute(page: page('Home'), path: '/'),
          AutoRoute(page: page('Detail'), path: '/detail'),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(
            platform: .iOS,
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values) platform: const CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          routerConfig: router.config(),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(router.push(const NamedRoute('Detail')));
      await tester.pumpAndSettle();
      expectTopPage(router, 'Detail');

      await swipeBack(tester);

      expectTopPage(router, 'Home');
      expect(router.stack.map((page) => page.name), ['Home']);
    });
  }
}
