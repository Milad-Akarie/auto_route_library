import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#157298: a stateful shell route inside another did not
// keep the inner branches' state when the outer branch changed.
// Setup: outer tabs A and B; B hosts inner tabs C and D.
// Steps: in B, open D and push a page in it; switch the outer tab to
// A, then back to B.
// Should: D is still the inner tab, the pushed page is still above it, and
// nothing was built a second time.
void main() {
  testWidgets('Switching the outer tab and back keeps the inner tab and its stack', (tester) async {
    final inits = <String, int>{};
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: _counted('OuterRoute', inits, child: const AutoTabsRouter(routes: [_Route('A'), _Route('B')])),
          children: [
            AutoRoute(path: 'a', page: _counted('A', inits)),
            AutoRoute(
              path: 'b',
              page: _counted('B', inits, child: const AutoTabsRouter(routes: [_Route('C'), _Route('D')])),
              children: [
                AutoRoute(path: 'c', page: _counted('C', inits)),
                AutoRoute(
                  path: 'd',
                  page: _counted('D', inits, child: const AutoRouter()),
                  children: [
                    AutoRoute(path: '', page: _counted('DHome', inits)),
                    AutoRoute(path: 'more', page: _counted('More', inits)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, initialLink: '/b/d');
    final outer = router.innerRouterOf<TabsRouter>('OuterRoute')!;
    final dHome = tester.element(find.text('DHome'));
    final inner = dHome.tabsRouter;
    expect(inner.activeIndex, 1);
    unawaited(dHome.router.push(const _Route('More')));
    await tester.pumpAndSettle();
    expect(find.text('More'), findsOneWidget);

    outer.setActiveIndex(0);
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    outer.setActiveIndex(1);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(inner.activeIndex, 1, reason: 'after outer.setActiveIndex(1)');
    expect(find.text('More'), findsOneWidget, reason: 'after outer.setActiveIndex(1)');
    expect(inits['D'], 1);
    expect(inits['B'], 1);
  });
}

PageInfo _counted(String name, Map<String, int> inits, {Widget? child}) =>
    .new(name, builder: (_) => _InitCounter(() => inits[name] = (inits[name] ?? 0) + 1, child: child ?? Text(name)));

class _InitCounter extends StatefulWidget {
  const _InitCounter(this.onInit, {required this.child});

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
  const _Route(super.name);
}
