import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _GameRoute extends PageRouteInfo<_GameArgs> {
  new({required String level}) : super(name, args: _GameArgs(level));

  static const name = 'GameRoute';
  static final page = PageInfo(
    name,
    builder: (data) => Builder(
      builder: (context) => Text(
        'Game ${data.argsAs<_GameArgs>().level} ${MediaQuery.widthOf(context).round()}',
      ),
    ),
  );
}

class _GameArgs {
  const new(this.level);
  final String level;
}

// https://github.com/Milad-Akarie/auto_route_library/issues/1146
// Steps: push a route that has a required arg, then resize the window.
// Reported: "GameRouteArgs can not be null because it has a required
// parameter" after the resize.
// Should: the page keeps its args and builds again with the new size.
void main() {
  testWidgets(
    'a page with required args builds again after the window is resized',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
          ),
          AutoRoute(path: '/game', page: _GameRoute.page),
        ],
      );
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      await pumpRouterApp(tester, router);
      unawaited(router.push(_GameRoute(level: 'hard')));
      await tester.pumpAndSettle();
      expect(find.text('Game hard 800'), findsOneWidget);

      tester.view.physicalSize = const Size(1200, 600);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Game hard 1200'), findsOneWidget);
    },
  );
}
