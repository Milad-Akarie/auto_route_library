import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  Widget person(BuildContext _, RouteData<Object?> data) => Scaffold(
    body: Center(
      child: Text(
        'person ${data.inheritedPathParams.getString('fid')}/${data.params.getString('pid')}',
      ),
    ),
  );

  RootStackRouter build() => .build(
    routes: [
      NamedRouteDef(
        name: 'HomeRoute',
        path: '/',
        builder: (_, _) => const CenteredNamedPage('HomeRoute'),
      ),
      NamedRouteDef(
        name: 'FamilyRoute',
        path: '/family/:fid',
        builder: (_, _) => const AutoRouter(),
        children: [
          NamedRouteDef(
            name: 'FamilyHomeRoute',
            path: '',
            builder: (_, _) => const CenteredNamedPage('FamilyHomeRoute'),
          ),
          NamedRouteDef(
            name: 'PersonRoute',
            path: 'person/:pid',
            builder: person,
          ),
        ],
      ),
    ],
  );

  // https://github.com/flutter/flutter/issues/99110
  // From '/', push a person together with the family it belongs to. The
  // person page should see both ids, and its url should have both.
  testWidgets(
    'push() of a nested route from an unrelated page keeps its parent params (flutter/flutter#99110)',
    (tester) async {
      final router = build();
      await pumpRouterApp(tester, router);
      unawaited(
        router.push(
          const NamedRoute(
            'FamilyRoute',
            params: {'fid': 'f2'},
            children: [
              NamedRoute('PersonRoute', params: {'pid': 'p1'}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('person f2/p1'), findsOneWidget);
      expect(router.urlState.url, '/family/f2/person/p1');
    },
  );

  // https://github.com/flutter/flutter/issues/104403
  // On a person page of family f2, push another person giving only 'pid' with
  // the nested router. The new page should read the family f2 it is under,
  // not fail with a missing 'fid'.
  testWidgets(
    'push() of a sibling from inside a nested router keeps the parent params (flutter/flutter#104403)',
    (tester) async {
      final router = build();
      await pumpRouterApp(tester, router, initialLink: '/family/f2/person/p1');
      expect(find.text('person f2/p1'), findsOneWidget);

      final context = tester.element(find.text('person f2/p1'));
      unawaited(
        context.router.push(
          const NamedRoute('PersonRoute', params: {'pid': 'p2'}),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('person f2/p2'), findsOneWidget);
      expect(router.urlState.url, '/family/f2/person/p2');
    },
  );
}
