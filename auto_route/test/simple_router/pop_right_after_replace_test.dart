import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#160111: a page is replaced and the new page popped in the
// same callback.
// Steps: open A, then B; call replace(C) then pop(). C replaces B and is
// popped, so A is left. pop() popped B before C was added, and C then showed
// over A.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('A'), initial: true),
        AutoRoute(page: _page('B')),
        AutoRoute(page: _page('C')),
      ],
    );
  });

  List<String> names() => router.stack.map((page) => page.routeData.name).toList();

  testWidgets('pop right after replace pops the new page', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('B')));
    await tester.pumpAndSettle();

    String? result;
    unawaited(router.replace<String>(const PageRouteInfo('C')).then((value) => result = value));
    router.pop('closed');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, 'closed');
    expect(names(), ['A']);
    expectTopPage(router, 'A');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Scaffold(body: Text(name)));
