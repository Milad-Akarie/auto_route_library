import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

PageInfo _sizePage(String name) => .new(
  name,
  builder: (_) => Builder(builder: (context) => Text('$name ${MediaQuery.sizeOf(context).width.round()}')),
);

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1746
  // Steps: a desktop app whose page lays out by the window's size, at the
  // root and inside a nested router. Resize the window.
  // Reported: the page isn't rebuilt, so it keeps the old layout.
  // Should: both pages build again with the new size.
  testWidgets('Pages build again with the new size when the window is resized', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/', page: _sizePage('HomeRoute')),
        AutoRoute(
          path: '/host',
          page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
          children: [AutoRoute(path: '', page: _sizePage('NestedRoute'))],
        ),
      ],
    );
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    await pumpRouterApp(tester, router);
    expect(find.text('HomeRoute 800'), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 600);
    await tester.pumpAndSettle();
    expect(find.text('HomeRoute 1200'), findsOneWidget);

    unawaited(router.push(const NamedRoute('HostRoute')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 600);
    await tester.pumpAndSettle();
    expect(find.text('NestedRoute 900'), findsOneWidget);
  });
}
