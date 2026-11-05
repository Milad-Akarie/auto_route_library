import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _Sauce {
  const new(this.name);

  final String name;
}

// flutter/flutter#163140: in go_router state.extra became null when the
// window was resized, because the page was built again from the url.
// Steps: push a page with an argument, resize the window.
// Should: the page builds again with the same argument.
void main() {
  testWidgets('A page keeps its arguments when the window is resized (flutter/flutter#163140)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/sauce',
          page: PageInfo('SauceRoute', builder: (data) => Text('Sauce ${data.argsAs<_Sauce>().name}')),
        ),
      ],
    );
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute<_Sauce>('SauceRoute', args: _Sauce('mustard'))));
    await tester.pumpAndSettle();
    expect(find.text('Sauce mustard'), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 600);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Sauce mustard'),
      findsOneWidget,
      reason: 'after tester.view.physicalSize = const Size(1200, 600)',
    );
  });
}
