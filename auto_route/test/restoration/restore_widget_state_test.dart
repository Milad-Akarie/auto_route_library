import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'restoration_test_utils.dart';

void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: page('HomeRoute'), initial: true),
      AutoRoute(
        page: PageInfo(
          'ListRoute',
          builder: (_) => Scaffold(
            body: ListView.builder(
              restorationId: 'list',
              itemExtent: 50,
              itemCount: 100,
              itemBuilder: (_, i) => Text('Item $i'),
            ),
          ),
        ),
      ),
    ],
  );

  // flutter/flutter#117683: in go_router, the scroll offset of a list with a
  // restorationId, and other restorable state of a page, was lost after the
  // platform ended and restored the app: the page had no restoration id.
  // Steps: push ListRoute, scroll its list 300 down, then let the platform
  // end and restore the app.
  // Should: ListRoute is back on top of HomeRoute, scrolled 300 down.
  testWidgets('a list keeps its scroll offset after restoration', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    unawaited(RestorableRouterApp.router.push(const NamedRoute('ListRoute')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final offset = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(offset, greaterThan(0));

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(RestorableRouterApp.router.stack.map((p) => p.name), ['HomeRoute', 'ListRoute']);
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, offset);
  }, skip: kIsWeb);
}
