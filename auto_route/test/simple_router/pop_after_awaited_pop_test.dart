import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/156809
  // In go_router, a page that popped itself as soon as the page it had pushed
  // returned threw "Bad state: Future already completed" and stayed.
  // Steps: First awaits push(Second); Second awaits push(Third), then pops
  // itself with Third's result; Third pops with 'done'.
  // Should: no exception; Second closes too, and First gets 'done'.
  testWidgets(
    'A page popping itself when its pushed page returns closes too (flutter/flutter#156809)',
    (tester) async {
      PageInfo page(String name) =>
          .new(name, builder: (_) => Scaffold(body: Text(name)));
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: page('First'), path: '/'),
          AutoRoute(page: page('Second'), path: '/second'),
          AutoRoute(page: page('Third'), path: '/third'),
        ],
      );
      await pumpRouterApp(tester, router);

      final firstResult = router.push<String>(const NamedRoute('Second'));
      await tester.pumpAndSettle();
      // What Second's button does, from Second's own context.
      final secondContext = tester.element(find.text('Second'));
      unawaited(
        secondContext.router.push<String>(const NamedRoute('Third')).then((
          result,
        ) {
          if (secondContext.mounted) secondContext.router.pop(result);
        }),
      );
      await tester.pumpAndSettle();
      expectTopPage(router, 'Third');

      router.pop('done');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(await firstResult, 'done');
      expect(router.stack.map((page) => page.name), ['First']);
      expect(find.text('First'), findsOneWidget);
    },
  );
}
