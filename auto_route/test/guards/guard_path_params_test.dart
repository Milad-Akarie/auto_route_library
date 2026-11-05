import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/123973
  // In go_router, a top-level redirect lost the path parameters of the route
  // it checked.
  // Steps: a global guard records resolver.route.params; open /p/myUser as the
  // app's first link, then push /p/otherUser.
  // Should: the guard sees username myUser, then otherUser. The deep link
  // includes its prefix match '/', so HomeRoute is checked first, with no
  // username of its own.
  testWidgets(
    'A global guard sees the path params of the route it checks (flutter/flutter#123973)',
    (tester) async {
      final seen = <String>[];
      final router = RootStackRouter.build(
        guards: [
          AutoRouteGuard.simple((resolver, _) {
            seen.add(
              '${resolver.routeName} ${resolver.route.params.optString('username') ?? 'null'}',
            );
            resolver.next();
          }),
        ],
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'ProfileRoute',
            path: '/p/:username',
            builder: (_, data) => Scaffold(
              body: Text('ProfileRoute ${data.params.getString('username')}'),
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/p/myUser');
      expect(seen, ['HomeRoute null', 'ProfileRoute myUser']);
      expect(find.text('ProfileRoute myUser'), findsOneWidget);

      unawaited(router.pushPath('/p/otherUser'));
      await tester.pumpAndSettle();

      expect(seen, [
        'HomeRoute null',
        'ProfileRoute myUser',
        'ProfileRoute otherUser',
      ]);
      expect(find.text('ProfileRoute otherUser'), findsOneWidget);
    },
  );
}
