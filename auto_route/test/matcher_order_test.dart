import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'centered_named_page.dart';
import 'router_test_utils.dart';

void main() {
  RootStackRouter build(List<String> order) => .build(
    routes: [
      NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => const CenteredNamedPage('HomeRoute')),
      for (final name in order)
        if (name == 'create')
          NamedRouteDef(
            name: 'CreateRoute',
            path: '/home/create',
            builder: (_, _) => const CenteredNamedPage('CreateRoute'),
          )
        else
          NamedRouteDef(
            name: 'DetailRoute',
            path: '/home/:id',
            builder: (_, data) => CenteredNamedPage('DetailRoute ${data.params.getString('id')}'),
          ),
    ],
  );

  // https://github.com/flutter/flutter/issues/99833
  // https://github.com/flutter/flutter/issues/106851
  // '/home/create' matches both a static route and '/home/:id'. The first
  // route in the list wins; '/home/7' only fits the param route.
  testWidgets('The first declared of two matching routes is opened (flutter/flutter#99833)', (tester) async {
    final router = build(['create', 'id']);
    await pumpRouterApp(tester, router, initialLink: '/home/create');
    expect(find.text('CreateRoute'), findsOneWidget);
    unawaited(router.pushPath('/home/7'));
    await tester.pumpAndSettle();
    expect(find.text('DetailRoute 7'), findsOneWidget);
  });

  testWidgets('The param route listed first takes the path of the static one (flutter/flutter#99833)', (tester) async {
    final router = build(['id', 'create']);
    await pumpRouterApp(tester, router, initialLink: '/home/create');
    expect(find.text('DetailRoute create'), findsOneWidget);
  });
}
