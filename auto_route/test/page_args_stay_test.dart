import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// flutter/flutter#122038, #129347 and #130602: in go_router, the extra object
// of a page was replaced by the one passed to a later go, came back null
// after a tab branch rebuilt, or was lost when a refresh ran the redirect.
// Setup: a shell route with two nested pages that take args, and a tabs
// router whose tab B takes args.
// Steps: open the parent with args 'p', push the child with args 'c', go
// back; open tab B with args, switch to tab A and back, and run the guards again.
// Should: each page keeps its own args, and the tab page is built once.
final _builds = <String>[];

PageInfo _argsPage(String name) => .new(
  name,
  builder: (data) {
    _builds.add(name);
    return Text('$name ${data.args ?? 'null'}');
  },
);

void main() {
  setUp(_builds.clear);

  testWidgets('A parent and its child in a shell keep their own args when the child is popped', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/shell',
          page: PageInfo('ShellRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(path: 'parent', page: _argsPage('ParentRoute')),
            AutoRoute(path: 'child', page: _argsPage('ChildRoute')),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const NamedRoute('ShellRoute', children: [NamedRoute('ParentRoute', args: 'p')])));
    await tester.pumpAndSettle();
    final inner = router.innerRouterOf<StackRouter>('ShellRoute')!;
    unawaited(inner.push(const NamedRoute('ChildRoute', args: 'c')));
    await tester.pumpAndSettle();
    expect(find.text('ChildRoute c'), findsOneWidget);

    await router.maybePopTop();
    await tester.pumpAndSettle();
    expect(find.text('ParentRoute p'), findsOneWidget);
  });

  testWidgets('A tab page keeps its args, and is built once, when the user leaves the tab and returns', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'TabsRoute',
            builder: (_) => const AutoTabsScaffold(
              routes: [
                NamedRoute('ARoute'),
                NamedRoute('BRoute', args: 'b'),
              ],
            ),
          ),
          children: [
            AutoRoute(path: 'a', page: _argsPage('ARoute')),
            AutoRoute(path: 'b', page: _argsPage('BRoute')),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    final tabs = router.innerRouterOf<TabsRouter>('TabsRoute')!;
    tabs.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text('BRoute b'), findsOneWidget);
    tabs.setActiveIndex(0);
    await tester.pumpAndSettle();
    tabs.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text('BRoute b'), findsOneWidget);
    expect(_builds.where((n) => n == 'BRoute'), hasLength(1));
  });
}
