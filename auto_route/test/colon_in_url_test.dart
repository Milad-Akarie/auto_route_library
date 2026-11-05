import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'main_router.dart';
import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/', initial: true),
        AutoRoute(
          page: PageInfo(
            'HomeRoute',
            builder: (data) =>
                Text('test ${data.queryParams.optString('test') ?? 'null'}'),
          ),
          path: '/home',
        ),
        AutoRoute(
          page: PageInfo(
            'TagRoute',
            builder: (data) =>
                Text('tag ${data.inheritedPathParams.getString('tag')}'),
          ),
          path: '/tag/:tag',
        ),
      ],
    );
  });

  // flutter/flutter#111354: in go_router, a query value holding a colon
  // followed by a number, as '/home?test=something:1', threw "Illegal
  // RegExp pattern": the url was turned into a pattern. auto_route compares
  // path segments as text, so such values read back as they are.
  // Steps: navigatePath to each url.
  // Should: no exception, and the page reads the value whole.
  for (final (url, text) in [
    ('/home?test=something:1', 'test something:1'),
    ('/home?test=:1', 'test :1'),
    ('/tag/a:1', 'tag a:1'),
  ]) {
    testWidgets('$url opens its page with the value whole', (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.navigatePath(url));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(text), findsOneWidget);
    });
  }
}
