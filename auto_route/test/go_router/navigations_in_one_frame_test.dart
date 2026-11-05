import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Two navigations started in the same frame, as when two buttons are tapped
// together, both land, in order, and leave no error.
// The same scenario as flutter/flutter#175519 in go_router, where the second
// relative navigation resolved against a location the first had not reached.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(
        path: '/',
        page: PageInfo('ARoute', builder: (_) => const _Buttons()),
        children: [
          AutoRoute(
            path: 'x',
            page: PageInfo('XRoute', builder: (_) => const Text('XRoute')),
          ),
          AutoRoute(
            path: 'y',
            page: PageInfo('YRoute', builder: (_) => const Text('YRoute')),
          ),
        ],
      ),
      AutoRoute(
        path: '/top-x',
        page: PageInfo('TopXRoute', builder: (_) => const Text('TopXRoute')),
      ),
      AutoRoute(
        path: '/top-y',
        page: PageInfo('TopYRoute', builder: (_) => const Text('TopYRoute')),
      ),
    ],
  );

  // Steps: ARoute shows; push TopXRoute and TopYRoute in one frame, by
  // name and by path. Should: the stack is [ARoute, TopXRoute, TopYRoute].
  final pushes = <String, void Function(StackRouter)>{
    'push': (router) {
      unawaited(router.push(const PageRouteInfo('TopXRoute')));
      unawaited(router.push(const PageRouteInfo('TopYRoute')));
    },
    'pushPath': (router) {
      unawaited(router.pushPath('/top-x'));
      unawaited(router.pushPath('/top-y'));
    },
  };
  for (final MapEntry(key: name, value: pushBoth) in pushes.entries) {
    testWidgets('two ${name}es in one frame push both pages in order', (
      tester,
    ) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);
      pushBoth(router);
      await tester.pumpAndSettle();
      expect(router.stack.map((page) => page.name), [
        'ARoute',
        'TopXRoute',
        'TopYRoute',
      ]);
      expect(find.text('TopYRoute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  // Steps: ARoute shows, with two buttons that navigate to its children
  // XRoute and YRoute; tap both in one frame. Should: YRoute, the last
  // navigation, is the child shown, and nothing throws.
  testWidgets(
    'two navigations to child pages tapped in one frame land on the last',
    (tester) async {
      final router = buildRouter();
      await pumpRouterApp(tester, router);
      await tester.tap(find.text('to x'));
      await tester.tap(find.text('to y'));
      await tester.pumpAndSettle();
      expect(router.stack.map((page) => page.name), ['ARoute']);
      expect(router.topMatch.name, 'YRoute');
      expect(find.text('YRoute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Buttons extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () => context.router.navigate(const PageRouteInfo('XRoute')),
        child: const Text('to x'),
      ),
      TextButton(
        onPressed: () => context.router.navigate(const PageRouteInfo('YRoute')),
        child: const Text('to y'),
      ),
      const Expanded(child: AutoRouter()),
    ],
  );
}
