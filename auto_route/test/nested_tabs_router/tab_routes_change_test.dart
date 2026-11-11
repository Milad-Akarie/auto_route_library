import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  tearDownAll(_signedInNotifier.dispose);
  _TabsKind.values.forEach(_runRoutesChangeTests);
}

void _runRoutesChangeTests(_TabsKind kind) {
  Future<void> pumpTabs(WidgetTester tester) async {
    // Cleared here, not in a teardown: the previous test's pages are disposed
    // after its teardowns run.
    _CountedPageState.initCounts.clear();
    _CountedPageState.disposeCounts.clear();
    addTearDown(() => _signedInNotifier.value = false);
    _tabsKind = kind;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _TabsHostRoute.page,
          path: '/',
          initial: true,
          children: [
            AutoRoute(page: _FirstTabRoute.page, path: 'first', initial: true),
            AutoRoute(page: _SecondTabRoute.page, path: 'second'),
            AutoRoute(page: _SignInTabRoute.page, path: 'sign-in'),
            AutoRoute(page: _AccountTabRoute.page, path: 'account'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text(_FirstTabRoute.name), findsOneWidget);
  }

  TabsRouter tabsRouterOf(WidgetTester tester) => AutoTabsRouter.of(
    tester.element(find.text(_FirstTabRoute.name, skipOffstage: false)),
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2314
  // Steps: an AutoTabsRouter has routes [first, second, signedIn ? account :
  // signIn]. Open the first tab, then flip signedIn so only the third route
  // changes.
  // Happens: the first and second tab pages are disposed and built again.
  // Should: the first tab page keeps its state; only the third tab changes.
  testWidgets(
    '${kind.name}: swapping one route in AutoTabsRouter.routes keeps the '
    'state of the active tab',
    (tester) async {
      await pumpTabs(tester);
      expect(_CountedPageState.initCounts[_FirstTabRoute.name], 1);

      _signedInNotifier.value = true;
      await tester.pumpAndSettle();
      expect(find.text(_FirstTabRoute.name), findsOneWidget);
      expect(_CountedPageState.disposeCounts[_FirstTabRoute.name], isNull);
      expect(
        _CountedPageState.initCounts[_FirstTabRoute.name],
        1,
        reason: 'after _signedInNotifier.value = true',
      );

      // The swapped tab shows its new route.
      tabsRouterOf(tester).setActiveIndex(2);
      await tester.pumpAndSettle();
      expect(find.text(_AccountTabRoute.name), findsOneWidget);
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2314
  // for a tab that is loaded but not active.
  // Steps: same routes as above. Open the second tab, go back to the first
  // one, then flip signedIn.
  // Happens: the second tab page is disposed and built again.
  // Should: the second tab page keeps its state.
  testWidgets(
    '${kind.name}: swapping one route in AutoTabsRouter.routes keeps the '
    'state of a loaded inactive tab',
    (tester) async {
      await pumpTabs(tester);
      tabsRouterOf(tester).setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(find.text(_SecondTabRoute.name), findsOneWidget);
      tabsRouterOf(tester).setActiveIndex(0);
      await tester.pumpAndSettle();
      expect(_CountedPageState.initCounts[_SecondTabRoute.name], 1);

      _signedInNotifier.value = true;
      await tester.pumpAndSettle();
      expect(_CountedPageState.disposeCounts[_SecondTabRoute.name], isNull);
      tabsRouterOf(tester).setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(
        find.text(_SecondTabRoute.name),
        findsOneWidget,
        reason: 'after tabsRouterOf(tester).setActiveIndex(1)',
      );
      expect(
        _CountedPageState.initCounts[_SecondTabRoute.name],
        1,
        reason: 'after tabsRouterOf(tester).setActiveIndex(1)',
      );
    },
  );
}

enum _TabsKind { indexedStack, pageView, tabBar, builder }

_TabsKind _tabsKind = .indexedStack;

final ValueNotifier<bool> _signedInNotifier = ValueNotifier(false);

abstract final class _TabsHostRoute {
  static const String name = '_TabsHostRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _signedInNotifier,
      builder: (context, isSignedIn, _) {
        final routes = [
          const _FirstTabRoute(),
          const _SecondTabRoute(),
          if (isSignedIn) const _AccountTabRoute() else const _SignInTabRoute(),
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
  const new() : super(name);

  static const String name = '_FirstTabRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const _CountedPage(name),
  );
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_SecondTabRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const _CountedPage(name),
  );
}

// Counts how often each tab page's state is created and disposed.
class _CountedPage extends StatefulWidget {
  const new(this.name);

  final String name;

  @override
  State<_CountedPage> createState() => _CountedPageState();
}

class _CountedPageState extends State<_CountedPage> {
  static final initCounts = <String, int>{};
  static final disposeCounts = <String, int>{};

  @override
  void initState() {
    super.initState();
    initCounts.update(widget.name, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  void dispose() {
    disposeCounts.update(widget.name, (count) => count + 1, ifAbsent: () => 1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(widget.name));
}

class _SignInTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_SignInTabRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text(name)),
  );
}

class _AccountTabRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_AccountTabRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text(name)),
  );
}
