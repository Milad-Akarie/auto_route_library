import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // https://github.com/flutter/flutter/issues/189503
  // In go_router, opening a detail page and pressing Android back quickly,
  // four or five times in a row, threw "'entry.currentState ==
  // _RouteLifecycle.idle || entry.route._popCompleter.isCompleted': is not
  // true" from NavigatorState.pop. Pages without a transition didn't.
  // Steps: on Android, ProductList opens ProductDetail with push, and system
  // back follows before the page has finished coming in; 20 times, with gaps
  // from none to a whole transition.
  // Should: no exception, and each back leaves ProductList alone on screen.
  for (final gap in const [
    Duration.zero,
    Duration(milliseconds: 16),
    Duration(milliseconds: 100),
    Duration(milliseconds: 300),
  ]) {
    testWidgets('Rapid push and system back on Android throw nothing, '
        '${gap.inMilliseconds} ms apart '
        '(flutter/flutter#189503)', (tester) async {
      PageInfo page(String name) =>
          .new(name, builder: (_) => Scaffold(body: Text(name)));
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: page('ProductList'), path: '/list', initial: true),
          AutoRoute(page: page('ProductDetail'), path: '/list/detail'),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: ThemeData(platform: .android),
          routerConfig: router.config(),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 20; i++) {
        unawaited(router.push(const NamedRoute('ProductDetail')));
        await tester.pump(gap);
        await tester.pump(gap);
        unawaited(tester.binding.handlePopRoute());
        await tester.pump(gap);
        await tester.pump(gap);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), ['ProductList']);
      expect(find.text('ProductDetail'), findsNothing);
    });
  }
}
