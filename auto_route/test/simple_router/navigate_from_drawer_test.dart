import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../no_op.dart';
import '../router_test_utils.dart';

// flutter/flutter#107804: a button in an open drawer navigates back to the
// first page. The drawer is a local history entry of its page's route, which
// the Navigator asks first when the page is removed.
// The reporter's steps: from Home, push Screen2; open its end drawer and tap
// the drawer's button, which goes to Home. Home should show, and pushing
// Screen2 again and going back to Home from it should still work.
void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('Home'), initial: true),
        AutoRoute(page: _page('Screen2')),
      ],
    );
  });

  List<String> names() => router.stack.map((page) => page.routeData.name).toList();

  // Each way the drawer's button can go back to Home.
  final goHomeCalls = <String, void Function(StackRouter router)>{
    'navigate': (activeRouter) => unawaited(activeRouter.navigate(const PageRouteInfo('Home'))),
    'replaceAll': (activeRouter) => unawaited(activeRouter.replaceAll(const [PageRouteInfo('Home')])),
    'popUntilRoot': (activeRouter) => activeRouter.popUntilRoot(),
  };

  for (final MapEntry(key: name, value: goHome) in goHomeCalls.entries) {
    testWidgets('$name from an open drawer shows Home, and Screen2 opens and closes again', (tester) async {
      _goHome = goHome;
      await pumpRouterApp(tester, router);
      unawaited(router.push(const PageRouteInfo('Screen2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go home from drawer'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(names(), ['Home']);
      expect(find.byType(Drawer), findsNothing);
      expectTopPage(router, 'Home');

      unawaited(router.push(const PageRouteInfo('Screen2')));
      await tester.pumpAndSettle();
      expectTopPage(router, 'Screen2');
      await tester.tap(find.text('Go home'));
      await tester.pumpAndSettle();
      expect(names(), ['Home'], reason: 'after tester.tap(find.text(Go home))');
      expectTopPage(router, 'Home');
    });
  }
}

void Function(StackRouter router) _goHome = ignoreArgument;

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(
    appBar: AppBar(
      actions: [
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            icon: const Icon(Icons.menu),
          ),
        ),
      ],
    ),
    endDrawer: Drawer(
      child: Builder(
        builder: (context) =>
            TextButton(onPressed: () => _goHome(context.router), child: const Text('Go home from drawer')),
      ),
    ),
    body: Builder(
      builder: (context) => Column(
        children: [
          Text(name),
          TextButton(onPressed: () => _goHome(context.router), child: const Text('Go home')),
        ],
      ),
    ),
  ),
);
