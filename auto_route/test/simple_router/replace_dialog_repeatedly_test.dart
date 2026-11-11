import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#114234: replacing the same route twice did the second time
// nothing, because both pages had the same key.
// Steps: open a dialog route for item 1, then replace it with item 2, then
// with item 3 (the reporter's arrow buttons).
// Should: each replace shows the new item.
void main() {
  testWidgets(
    'Replacing a dialog route with itself several times shows each item',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const Text('home'),
          ),
          NamedRouteDef(
            name: 'ItemRoute',
            path: '/item/:id',
            type: RouteType.custom(opaque: false),
            builder: (_, data) =>
                Center(child: Text('item ${data.params.getString('id')}')),
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      unawaited(
        router.push(const NamedRoute('ItemRoute', params: {'id': '1'})),
      );
      await tester.pumpAndSettle();
      for (final id in ['2', '3']) {
        unawaited(router.replace(NamedRoute('ItemRoute', params: {'id': id})));
        await tester.pumpAndSettle();
        expect(find.text('item $id'), findsOneWidget);
        expect(router.currentUrl, '/item/$id');
      }
      expect(router.stack.map((p) => p.name), ['HomeRoute', 'ItemRoute']);
      expect(find.text('home'), findsOneWidget);
    },
  );
}
