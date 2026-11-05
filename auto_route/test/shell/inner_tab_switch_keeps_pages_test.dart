import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/flutter/flutter/issues/158934
// Setup: the first page holds tabs; a sample page is pushed above it, and
// above that a second tabs page with its own bottom bar.
// Steps: switch the second tabs page to its second tab, then back to its
// first.
// Should: the pages below stay in the stack throughout and are neither
// rebuilt from scratch nor removed.
void main() {
  testWidgets('Switching inner tabs keeps the pages below and their state', (tester) async {
    final inits = <String, int>{};
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: _counted('TabsRoute', inits, child: const AutoTabsRouter(routes: [_Route('Tab1')])),
          children: [AutoRoute(path: '', page: _counted('Tab1', inits))],
        ),
        AutoRoute(path: '/sample', page: _counted('SampleRoute', inits)),
        AutoRoute(
          path: '/another',
          page: _counted(
            'AnotherTabsRoute',
            inits,
            child: const AutoTabsRouter(routes: [_Route('Item0'), _Route('Item1')]),
          ),
          children: [
            AutoRoute(path: 'item0', page: _counted('Item0', inits)),
            AutoRoute(path: 'item1', page: _counted('Item1', inits)),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const _Route('SampleRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const _Route('AnotherTabsRoute')));
    await tester.pumpAndSettle();
    final names = ['TabsRoute', 'SampleRoute', 'AnotherTabsRoute'];
    expect(router.stack.map((page) => page.name), names);
    final inner = router.innerRouterOf<TabsRouter>('AnotherTabsRoute')!;

    for (final index in [1, 0, 1]) {
      inner.setActiveIndex(index);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Item$index'), findsOneWidget);
      expect(router.stack.map((page) => page.name), names);
      for (final name in ['Tab1', 'SampleRoute']) {
        expect(find.text(name, skipOffstage: false), findsOneWidget);
      }
    }
    expect(inits, {'TabsRoute': 1, 'Tab1': 1, 'SampleRoute': 1, 'AnotherTabsRoute': 1, 'Item0': 1, 'Item1': 1});
  });
}

PageInfo _counted(String name, Map<String, int> inits, {Widget? child}) =>
    .new(name, builder: (_) => _InitCounter(() => inits[name] = (inits[name] ?? 0) + 1, child: child ?? Text(name)));

class _InitCounter extends StatefulWidget {
  const new(this.onInit, {required this.child});

  final VoidCallback onInit;
  final Widget child;

  @override
  State<_InitCounter> createState() => _InitCounterState();
}

class _InitCounterState extends State<_InitCounter> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: widget.child);
}

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
