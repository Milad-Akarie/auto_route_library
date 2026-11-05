import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Pages build again with the new size when the window is resized.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/1746
// Headless test: auto_route/test/simple_router/window_resize_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: pages lay out by the window's size, at the root and inside a nested
  // router. Change the size the app sees.
  // Should: each page shows the new width.
  testWidgets(
    'pages build again with the new size when the window is resized',
    (tester) async {
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
      tester.view.physicalSize = const Size(400, 700);
      await pumpRouterApp(tester, router);
      expect(find.text('HomeRoute 400'), findsOneWidget);

      tester.view.physicalSize = const Size(500, 700);
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute 500'), findsOneWidget);

      unawaited(router.push(const NamedRoute('HostRoute')));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(450, 700);
      await tester.pumpAndSettle();
      expect(find.text('NestedRoute 450'), findsOneWidget);
    },
  );
}

PageInfo _sizePage(String name) => .new(
  name,
  builder: (_) => Builder(
    builder: (context) =>
        Scaffold(body: Text('$name ${MediaQuery.widthOf(context).round()}')),
  ),
);
