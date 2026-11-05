import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Other tabs keep their state when one route in AutoTabsRouter.routes changes.
// https://github.com/Milad-Akarie/auto_route_library/issues/2314
// Headless test: auto_route/test/nested_tabs_router/tab_routes_change_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final kind in _TabsKind.values) {
    // Steps: tabs are [first, second, signedIn ? account : sign-in]. Tap the
    // first tab's counter twice, open the second tab and tap its counter
    // once, go back to the first tab, then tap 'Sign in' so only the third
    // route changes.
    // Should: the first tab still shows 2 taps, the second still shows 1, and
    // the third tab shows the account page.
    testWidgets(
      "${kind.name}: signing in swaps the third tab and keeps the other tabs' state",
      (tester) async {
        addTearDown(() => _signedInNotifier.value = false);
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
                AutoRoute(page: _SignInTabRoute.page, path: 'sign-in'),
                AutoRoute(page: _AccountTabRoute.page, path: 'account'),
              ],
            ),
          ],
        );
        await pumpRouterConfigApp(
          tester,
          router.config(deepLinkBuilder: (_) => DeepLink.defaultPath),
        );

        await tester.tap(find.text('First: add one'));
        await tester.tap(find.text('First: add one'));
        await tester.pumpAndSettle();
        expect(find.text('First taps: 2'), findsOneWidget);

        await tester.tap(find.text('Go to second tab'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Second: add one'));
        await tester.pumpAndSettle();
        expect(find.text('Second taps: 1'), findsOneWidget);
        await tester.tap(find.text('Go to first tab'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();
        expect(find.text('First taps: 2'), findsOneWidget);

        await tester.tap(find.text('Go to second tab'));
        await tester.pumpAndSettle();
        expect(find.text('Second taps: 1'), findsOneWidget);

        await tester.tap(find.text('Go to third tab'));
        await tester.pumpAndSettle();
        expect(find.text(_AccountTabRoute.name), findsOneWidget);
      },
    );
  }
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

final _signedInNotifier = ValueNotifier<bool>(false);

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _signedInNotifier,
      builder: (context, signedIn, _) {
        final routes = [
          const _FirstTabRoute(),
          const _SecondTabRoute(),
          if (signedIn) const _AccountTabRoute() else const _SignInTabRoute(),
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
    builder: (_) => _CounterPage(
      label: 'First',
      actions: [
        const _TabButton('Go to second tab', index: 1),
        TextButton(
          onPressed: () => _signedInNotifier.value = true,
          child: const Text('Sign in'),
        ),
      ],
    ),
  );
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const _CounterPage(
      label: 'Second',
      actions: [
        _TabButton('Go to first tab', index: 0),
        _TabButton('Go to third tab', index: 2),
      ],
    ),
  );
}

class _SignInTabRoute extends PageRouteInfo<void> {
  const _SignInTabRoute() : super(name);

  static const String name = '_SignInTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text(name))),
  );
}

class _AccountTabRoute extends PageRouteInfo<void> {
  const _AccountTabRoute() : super(name);

  static const String name = '_AccountTabRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: SafeArea(child: Text(name))),
  );
}

// A tab page with a tap counter, the state the tabs must keep.
class _CounterPage extends StatefulWidget {
  const _CounterPage({required this.label, required this.actions});

  final String label;
  final List<Widget> actions;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text('${widget.label} taps: $_taps'),
            TextButton(
              onPressed: () => setState(() => _taps++),
              child: Text('${widget.label}: add one'),
            ),
            ...widget.actions,
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton(this.label, {required this.index});

  final String label;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.tabsRouter.setActiveIndex(index),
      child: Text(label),
    );
  }
}
