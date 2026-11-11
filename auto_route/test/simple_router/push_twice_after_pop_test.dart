import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#154759: push, pop, then push the same page again showed it
// twice, or the pop did not remove it.
// Steps: on A, push B, pop it, and push B again, each settling. One B should
// show: the first B's State is disposed, and B's State is made once per push.
// Also inside a tab's stack.
void main() {
  setUp(_events.clear);

  testWidgets('push, pop, push in a flat stack shows one B', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('A'), initial: true),
        AutoRoute(page: _counted),
      ],
    );
    await pumpRouterApp(tester, router);

    await _pushPopPush(tester, router);

    expect(_events, ['initState', 'dispose', 'initState']);
    expect(find.text(_counted.name), findsOneWidget);
    expect(router.stack.map((page) => page.routeData.name), [
      'A',
      _counted.name,
    ]);
  });

  testWidgets("push, pop, push in a tab's stack shows one B", (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'TabsScreen',
            builder: (_) => const AutoTabsRouter(
              routes: [PageRouteInfo('HomeTab'), PageRouteInfo('Profile')],
            ),
          ),
          path: '/',
          children: [
            AutoRoute(
              page: PageInfo('HomeTab', builder: (_) => const AutoRouter()),
              path: 'home',
              children: [
                AutoRoute(page: _page('A'), path: ''),
                AutoRoute(page: _counted, path: 'b'),
              ],
            ),
            AutoRoute(page: _page('Profile'), path: 'profile'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final tabStack = router
        .innerRouterOf<TabsRouter>('TabsScreen')!
        .innerRouterOf<StackRouter>('HomeTab')!;

    await _pushPopPush(tester, tabStack);

    expect(_events, ['initState', 'dispose', 'initState']);
    expect(find.text(_counted.name), findsOneWidget);
    expect(tabStack.stack.map((page) => page.routeData.name), [
      'A',
      _counted.name,
    ]);
  });
}

Future<void> _pushPopPush(WidgetTester tester, StackRouter router) async {
  unawaited(router.push(PageRouteInfo(_counted.name)));
  await tester.pumpAndSettle();
  router.pop();
  await tester.pumpAndSettle();
  unawaited(router.push(PageRouteInfo(_counted.name)));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

final _events = <String>[];

final _counted = PageInfo('B', builder: (_) => const _CountedPage());

class _CountedPage extends StatefulWidget {
  const new();

  @override
  State<_CountedPage> createState() => _CountedPageState();
}

class _CountedPageState extends State<_CountedPage> {
  @override
  void initState() {
    super.initState();
    _events.add('initState');
  }

  @override
  void dispose() {
    _events.add('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('B'));
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
