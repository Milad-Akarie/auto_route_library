import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The active tab is kept when AutoTabsRouter is rebuilt.
// https://github.com/Milad-Akarie/auto_route_library/pull/2081
// Headless test: auto_route/test/nested_tabs_router/tab_rebuild_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('tab rebuild', () {
    // Steps: a page holds AutoTabsRouter.tabBar under a widget whose state
    // decides the layout around it. Switch to the second tab, then change that
    // state so AutoTabsRouter.tabBar is built again from scratch.
    // Should: the second tab stays active and the url stays '/second'.
    testWidgets(
      'Rebuilding the layout above AutoTabsRouter.tabBar keeps the active tab',
      (tester) async {
        addTearDown(() => _layoutNotifier.value = false);
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: _TabsHostRoute.page,
              path: '/',
              initial: true,
              children: [
                AutoRoute(
                  page: _FirstTabRoute.page,
                  path: 'first',
                  initial: true,
                ),
                AutoRoute(page: _SecondTabRoute.page, path: 'second'),
              ],
            ),
          ],
        );
        await pumpRouterConfigApp(
          tester,
          router.config(deepLinkBuilder: (_) => DeepLink.defaultPath),
        );
        expect(find.text(_FirstTabRoute.name), findsOneWidget);

        await tester.tap(find.text('Go to second tab'));
        await tester.pumpAndSettle();
        expect(find.text(_SecondTabRoute.name), findsOneWidget);
        expect(router.urlState.path, '/second');

        _layoutNotifier.value = !_layoutNotifier.value;
        await tester.pumpAndSettle();
        expect(find.text('Side panel'), findsOneWidget);
        expect(find.text(_SecondTabRoute.name), findsOneWidget);
        expect(router.urlState.path, '/second');
        await expectBrowserUrl('/second');
      },
    );
  });
}

// Flips the layout around the tabs: false keeps them alone, true puts a side
// panel next to them.
final ValueNotifier<bool> _layoutNotifier = ValueNotifier(false);

class _TabsHostRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _layoutNotifier,
      builder: (context, hasSidePanel, _) {
        final tabs = AutoTabsRouter.tabBar(
          routes: const [_FirstTabRoute(), _SecondTabRoute()],
          builder: (context, child, _) => child,
        );
        if (!hasSidePanel) return tabs;
        return Row(
          children: [
            const SafeArea(child: Text('Side panel')),
            Expanded(child: tabs),
          ],
        );
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const Text(name),
              TextButton(
                onPressed: () => context.tabsRouter.setActiveIndex(1),
                child: const Text('Go to second tab'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text(name))),
  );
}
