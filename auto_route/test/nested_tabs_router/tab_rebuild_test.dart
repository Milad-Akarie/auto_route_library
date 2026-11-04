import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  RootStackRouter buildRouter() => RootStackRouter.build(
    routes: [
      AutoRoute(
        page: _TabsHostRoute.page,
        path: '/',
        initial: true,
        children: [
          AutoRoute(page: _FirstTabRoute.page, path: 'first', initial: true),
          AutoRoute(page: _SecondTabRoute.page, path: 'second'),
        ],
      ),
    ],
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2081
  // Steps: a page holds AutoTabsRouter.tabBar under a widget whose state
  // decides the layout around it. Switch to the second tab, then change that
  // state so the layout around the tabs changes and AutoTabsRouter.tabBar is
  // built again from scratch.
  // Happens: the first tab shows again while the url stays '/second'.
  // Should: the second tab stays active.
  testWidgets('Rebuilding the layout above AutoTabsRouter.tabBar keeps the active tab', (WidgetTester tester) async {
    addTearDown(() => _layoutNotifier.value = false);
    final router = buildRouter();
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text(_FirstTabRoute.name), findsOneWidget);

    await tester.tap(find.text('Go to second tab'));
    await tester.pumpAndSettle();
    expect(find.text(_SecondTabRoute.name), findsOneWidget);
    expect(router.urlState.path, '/second');

    _layoutNotifier.value = !_layoutNotifier.value;
    await tester.pumpAndSettle();
    expect(find.text(_SecondTabRoute.name), findsOneWidget);
    expect(router.urlState.path, '/second');
  });
}

// Flips the layout around the tabs: false keeps them alone, true puts a side
// panel next to them.
final _layoutNotifier = ValueNotifier<bool>(false);

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _layoutNotifier,
      builder: (context, withSidePanel, _) {
        final tabs = AutoTabsRouter.tabBar(
          routes: const [_FirstTabRoute(), _SecondTabRoute()],
          builder: (context, child, _) => child,
        );
        if (!withSidePanel) return tabs;
        return Row(
          children: [
            const Text('Side panel'),
            Expanded(child: tabs),
          ],
        );
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: Column(
          children: [
            const Text(name),
            TextButton(onPressed: () => context.tabsRouter.setActiveIndex(1), child: const Text('Go to second tab')),
          ],
        ),
      ),
    ),
  );
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
