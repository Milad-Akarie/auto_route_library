import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

PageInfo _page(String name) => .new(name, builder: (_) => Center(child: Text(name)));

void main() {
  // #554: an AutoTabsScaffold whose `routes` list depends on state (a tab
  // shown only when the user is signed in). Steps: build it with two tabs,
  // rebuild it with three, then back to two.
  // Should: the tabs router follows the list: its pageCount changes, and the
  // new tab opens.
  group('#554 AutoTabsScaffold routes that change at runtime', () {
    late ValueNotifier<bool> signedIn;
    late RootStackRouter router;

    setUp(() {
      signedIn = ValueNotifier(false);
      router = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo(
              'HostRoute',
              builder: (_) => ValueListenableBuilder<bool>(
                valueListenable: signedIn,
                builder: (_, isIn, _) => AutoTabsScaffold(
                  routes: [
                    const PageRouteInfo('ATab'),
                    if (isIn) const PageRouteInfo('AccountTab'),
                    const PageRouteInfo('BTab'),
                  ],
                  bottomNavigationBuilder: (_, tabs) => BottomNavigationBar(
                    currentIndex: tabs.activeIndex,
                    onTap: tabs.setActiveIndex,
                    items: [
                      for (var i = 0; i < tabs.pageCount; i++)
                        BottomNavigationBarItem(icon: const Icon(Icons.abc), label: 'item$i'),
                    ],
                  ),
                ),
              ),
            ),
            children: [
              AutoRoute(page: _page('ATab')),
              AutoRoute(page: _page('AccountTab')),
              AutoRoute(page: _page('BTab')),
            ],
          ),
        ],
      );
    });

    testWidgets('the tabs follow the list', (tester) async {
      await pumpRouterApp(tester, router);
      final tabs = router.innerRouterOf<TabsRouter>('HostRoute')!;
      expect(tabs.pageCount, 2);

      signedIn.value = true;
      await tester.pumpAndSettle();
      expect(tabs.pageCount, 3);
      expect(tabs.stackData.map((e) => e.name), ['ATab', 'AccountTab', 'BTab']);
      await tester.tap(find.text('item1'));
      await tester.pumpAndSettle();
      expect(find.text('AccountTab'), findsOneWidget);

      signedIn.value = false;
      await tester.pumpAndSettle();
      expect(tabs.pageCount, 2);
      expect(tabs.stackData.map((e) => e.name), ['ATab', 'BTab']);
      expect(find.text('AccountTab'), findsNothing);
    });
  });

  // #549: AutoTabsScaffold wrapped the app bar in a PreferredSize of
  // kToolbarHeight, so a taller AppBar was cut. Steps: appBarBuilder returns
  // an AppBar with toolbarHeight 120. Should: the app bar is 120 tall.
  testWidgets('#549 appBarBuilder keeps the height of the app bar it returns', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          initial: true,
          page: PageInfo(
            'HostRoute',
            builder: (_) =>
                AutoTabsScaffold(appBarBuilder: (_, _) => AppBar(title: const Text('Tall'), toolbarHeight: 120)),
          ),
          children: [
            AutoRoute(page: _page('ATab')),
            AutoRoute(page: _page('BTab')),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(tester.getSize(find.byType(AppBar)).height, 120);
  });

  // #435: pushAndRemoveUntil(DashboardPage, predicate: (_) => false) built the
  // page more than 8 times (release mode only). In auto_route 11 the call is
  // pushAndPopUntil. Steps: push a page, pushAndPopUntil a page that counts
  // its initState calls. Should: once.
  testWidgets('#435 pushAndPopUntil builds the new page once', (tester) async {
    _initStates = 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(initial: true, page: _page('HomeRoute')),
        AutoRoute(page: _page('MiddleRoute')),
        AutoRoute(page: PageInfo('DashboardRoute', builder: (_) => const _Counting())),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('MiddleRoute')));
    await tester.pumpAndSettle();

    unawaited(router.pushAndPopUntil(const PageRouteInfo('DashboardRoute'), predicate: (_) => false));
    await tester.pumpAndSettle();

    expect(_initStates, 1);
    expect(router.stack.map((p) => p.name), ['DashboardRoute']);
  });
}

int _initStates = 0;

class _Counting extends StatefulWidget {
  const _Counting();

  @override
  State<_Counting> createState() => _CountingState();
}

class _CountingState extends State<_Counting> {
  @override
  void initState() {
    super.initState();
    _initStates++;
  }

  @override
  Widget build(BuildContext context) => const Text('Dashboard');
}
