import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Removing the tab before the active tab keeps the active tab shown, with its state.
// https://github.com/Milad-Akarie/auto_route_library/issues/1786
// Headless test: auto_route/test/nested_tabs_router/tab_removed_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final kind in _TabsKind.values) {
    // Steps: tabs are [first, second, third]. Open the second tab, then the
    // third, tap the third tab's counter once, then tap 'Remove second tab'.
    // Should: the third tab still shows 1 tap, on screen, and the first tab
    // is one step back.
    testWidgets(
      '${kind.name}: removing the second tab keeps the third tab shown',
      (tester) async {
        addTearDown(() => _secondRemovedNotifier.value = false);
        _tabsKind = kind;
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
                AutoRoute(page: _ThirdTabRoute.page, path: 'third'),
              ],
            ),
          ],
        );
        await pumpRouterConfigApp(
          tester,
          router.config(deepLinkBuilder: (_) => DeepLink.defaultPath),
        );

        await tester.tap(find.text('First: next tab'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Second: next tab'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Third: add one'));
        await tester.pumpAndSettle();
        expect(find.text('Third taps: 1'), findsOneWidget);

        await tester.tap(find.text('Remove second tab'));
        await tester.pumpAndSettle();
        expect(find.text('Second taps: 0'), findsNothing);
        expect(find.text('Third taps: 1'), findsOneWidget);
        _expectOnScreen(tester, find.text('Third taps: 1'));

        await tester.tap(find.text('Third: previous tab'));
        await tester.pumpAndSettle();
        expect(find.text('First taps: 0'), findsOneWidget);
        _expectOnScreen(tester, find.text('First taps: 0'));
      },
    );
  }
}

// The page views keep the pages beside the active one laid out off screen.
void _expectOnScreen(WidgetTester tester, Finder finder) {
  final screenWidth =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final left = tester.getTopLeft(finder).dx;
  expect(
    left >= 0 && left < screenWidth / 2,
    isTrue,
    reason: 'left edge at $left',
  );
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

final _secondRemovedNotifier = ValueNotifier<bool>(false);

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _secondRemovedNotifier,
      builder: (context, secondRemoved, _) {
        final routes = [
          const _FirstTabRoute(),
          if (!secondRemoved) const _SecondTabRoute(),
          const _ThirdTabRoute(),
        ];
        return switch (_tabsKind) {
          .indexedStack => AutoTabsRouter(routes: routes),
          .pageView => AutoTabsRouter.pageView(routes: routes),
          .tabBar => AutoTabsRouter.tabBar(routes: routes),
          .builder => AutoTabsRouter.builder(
            routes: routes,
            builder: (context, children, tabsRouter) =>
                IndexedStack(index: tabsRouter.activeIndex, children: children),
          ),
        };
      },
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const _CounterPage(label: 'First'),
  );
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const _CounterPage(label: 'Second'),
  );
}

class _ThirdTabRoute extends PageRouteInfo<void> {
  const _ThirdTabRoute() : super(name);

  static const String name = '_ThirdTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => _CounterPage(
      label: 'Third',
      actions: [
        TextButton(
          onPressed: () => _secondRemovedNotifier.value = true,
          child: const Text('Remove second tab'),
        ),
      ],
    ),
  );
}

// A tab page with a tap counter, the state the tabs must keep, and buttons
// to the tabs beside it.
class _CounterPage extends StatefulWidget {
  const _CounterPage({required this.label, this.actions = const []});

  final String label;
  final List<Widget> actions;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) {
    final tabsRouter = context.tabsRouter;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text('${widget.label} taps: $_taps'),
            TextButton(
              onPressed: () => setState(() => _taps++),
              child: Text('${widget.label}: add one'),
            ),
            TextButton(
              onPressed: () =>
                  tabsRouter.setActiveIndex(tabsRouter.activeIndex + 1),
              child: Text('${widget.label}: next tab'),
            ),
            TextButton(
              onPressed: () =>
                  tabsRouter.setActiveIndex(tabsRouter.activeIndex - 1),
              child: Text('${widget.label}: previous tab'),
            ),
            ...widget.actions,
          ],
        ),
      ),
    );
  }
}
