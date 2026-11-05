import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A tab-bar AutoTabsRouter removed while its tab bar animates, after a routes
// change, throws nothing.
// https://github.com/Milad-Akarie/auto_route_library/issues/1765
// Headless test: auto_route/test/nested_tabs_router/tab_bar_dispose_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: tabs are [first, second, third] with a two-second tab animation.
  // Tap the third tab, tap 'Add tab' while the tab bar moves, then tap
  // 'Close tabs' before it stops.
  // Should: the tabs close without an error.
  testWidgets('closing the tabs while the tab bar animates after a routes change throws nothing', (tester) async {
    addTearDown(() {
      _fourthAddedNotifier.value = false;
      _showTabsNotifier.value = true;
    });
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _TabsHostRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _FirstTabRoute.page, path: 'first', initial: true),
            AutoRoute(page: _SecondTabRoute.page, path: 'second'),
            AutoRoute(page: _ThirdTabRoute.page, path: 'third'),
            AutoRoute(page: _FourthTabRoute.page, path: 'fourth'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config(deepLinkBuilder: (_) => DeepLink.defaultPath));

    await tester.tap(find.text('Third'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Add tab'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Close tabs'));
    await tester.pumpAndSettle();
    expect(find.text('No tabs'), findsOneWidget);
  });
}

final _fourthAddedNotifier = ValueNotifier<bool>(false);

final _showTabsNotifier = ValueNotifier<bool>(true);

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ListenableBuilder(
      listenable: Listenable.merge([_fourthAddedNotifier, _showTabsNotifier]),
      builder: (context, _) {
        if (!_showTabsNotifier.value) return const Scaffold(body: SafeArea(child: Text('No tabs')));
        final labels = ['First', 'Second', 'Third', if (_fourthAddedNotifier.value) 'Fourth'];
        return AutoTabsRouter.tabBar(
          duration: const Duration(seconds: 2),
          routes: [
            const _FirstTabRoute(),
            const _SecondTabRoute(),
            const _ThirdTabRoute(),
            if (_fourthAddedNotifier.value) const _FourthTabRoute(),
          ],
          builder: (context, child, tabController) => Scaffold(
            appBar: AppBar(
              actions: [
                TextButton(onPressed: () => _fourthAddedNotifier.value = true, child: const Text('Add tab')),
                TextButton(onPressed: () => _showTabsNotifier.value = false, child: const Text('Close tabs')),
              ],
              bottom: TabBar(
                controller: tabController,
                tabs: [for (final label in labels) Tab(text: label)],
              ),
            ),
            body: child,
          ),
        );
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _ThirdTabRoute extends PageRouteInfo<void> {
  const _ThirdTabRoute() : super(name);

  static const String name = '_ThirdTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _FourthTabRoute extends PageRouteInfo<void> {
  const _FourthTabRoute() : super(name);

  static const String name = '_FourthTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}
