import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Each call an _AwarePage gets from its AutoRouteObserver, as '<route name>.<call>'.
final _events = <String>[];

class _AwarePage extends StatefulWidget {
  const _AwarePage();

  @override
  State<_AwarePage> createState() => _AwarePageState();
}

class _AwarePageState extends State<_AwarePage> with AutoRouteAwareStateMixin<_AwarePage> {
  late final String _name = context.routeData.name;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(context.routeData.name));

  @override
  void didPush() => _events.add('$_name.didPush');

  @override
  void didPop() => _events.add('$_name.didPop');

  @override
  void didPushNext() => _events.add('$_name.didPushNext');

  @override
  void didPopNext() => _events.add('$_name.didPopNext');
}

class _Route extends PageRouteInfo<void> {
  const _Route(super.name, {List<PageRouteInfo>? children}) : super(initialChildren: children);
}

PageInfo _awarePage(String name) => .new(name, builder: (_) => const _AwarePage());

PageInfo _stackHost(String name) => .new(name, builder: (_) => const AutoRouter());

/// Shows [routes] with a fresh [AutoRouteObserver] for each router, as the
/// README asks, then clears the calls the first pages got.
Future<RootStackRouter> _pumpApp(WidgetTester tester, List<AutoRoute> routes) async {
  final router = RootStackRouter.build(routes: routes);
  await pumpRouterConfigApp(tester, router.config(navigatorObservers: () => [AutoRouteObserver()]));
  _events.clear();
  return router;
}

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1954
  // Steps: route A hosts a nested router showing route B, both with
  // AutoRouteAwareStateMixin. Push route C at the root, then pop it.
  // Happens: A's didPushNext and didPopNext fire, B's never do.
  // Should: B hears both, since it is the page covered and shown again.
  testWidgets('A page in a nested router hears a root route cover and uncover its host', (tester) async {
    final router = await _pumpApp(tester, [
      AutoRoute(
        path: '/',
        page: _stackHost('A'),
        children: [AutoRoute(path: '', page: _awarePage('B'))],
      ),
      AutoRoute(path: '/c', page: _awarePage('C')),
    ]);

    router.push(const _Route('C'));
    await tester.pumpAndSettle();
    expect(_events, ['B.didPushNext', 'C.didPush']);

    _events.clear();
    router.pop();
    await tester.pumpAndSettle();
    expect(_events, ['B.didPopNext', 'C.didPop']);
  });

  // Same as above with two pages in the nested router: only the one on top
  // shows inside the host, so only that one hears its host covered.
  testWidgets('A page covered inside its nested router is not told again when the host is covered', (tester) async {
    final router = await _pumpApp(tester, [
      AutoRoute(
        path: '/',
        page: _stackHost('A'),
        children: [
          AutoRoute(path: '', page: _awarePage('B1')),
          AutoRoute(path: 'b2', page: _awarePage('B2')),
        ],
      ),
      AutoRoute(path: '/c', page: _awarePage('C')),
    ]);
    router.innerRouterOf<StackRouter>('A')!.push(const _Route('B2'));
    await tester.pumpAndSettle();
    expect(_events, ['B1.didPushNext', 'B2.didPush']);

    _events.clear();
    router.push(const _Route('C'));
    await tester.pumpAndSettle();
    expect(_events, ['B2.didPushNext', 'C.didPush']);

    _events.clear();
    router.pop();
    await tester.pumpAndSettle();
    expect(_events, ['B2.didPopNext', 'C.didPop']);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2306
  // Steps: AppRoute hosts tabs [Dashboard, Settings]; the Settings tab hosts
  // a nested router showing Something, a page with AutoRouteAware. Open the
  // Settings tab, push BottomSheetRoute, a CustomRoute that builds a
  // ModalBottomSheetRoute, on the root router, then close the sheet.
  // Happened: Something heard the sheet open only when the sheet was declared
  // in its own router; declared at the root, it heard neither open nor close.
  // Should: Something gets didPushNext, then didPopNext; the inactive
  // Dashboard tab hears nothing. The #1954 fix covers this.
  testWidgets('A page in a tab hears a root bottom sheet open and close over it', (tester) async {
    final router = await _pumpApp(tester, [
      AutoRoute(
        path: '/',
        page: PageInfo(
          'AppRoute',
          builder: (_) => const AutoTabsRouter(routes: [_Route('Dashboard'), _Route('Settings')]),
        ),
        children: [
          AutoRoute(path: 'dashboard', page: _awarePage('Dashboard')),
          AutoRoute(
            path: 'settings',
            page: _stackHost('Settings'),
            children: [AutoRoute(path: '', page: _awarePage('Something'))],
          ),
        ],
      ),
      CustomRoute<dynamic>(
        path: '/bottom-sheet',
        page: PageInfo('BottomSheetRoute', builder: (_) => const Text('sheet')),
        customRouteBuilder: <T>(context, child, page) =>
            ModalBottomSheetRoute<T>(settings: page, isScrollControlled: true, builder: (_) => child),
      ),
    ]);
    router.innerRouterOf<TabsRouter>('AppRoute')!.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(find.text('Something'), findsOneWidget);

    _events.clear();
    router.root.push(const _Route('BottomSheetRoute'));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
    expect(_events, ['Something.didPushNext']);

    _events.clear();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(_events, ['Something.didPopNext']);
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1863
  // The report gives no setup; this is the one where didPop never fired on
  // dev: the page is inside a nested router and its host route is popped.
  // Steps: Home, then route A that hosts a nested router showing route B, all
  // with AutoRouteAwareStateMixin. Pop A.
  // Happens: B gets didPush when it shows, but never didPop.
  // Should: B gets didPop, as a page popped in its own router does.
  testWidgets('A page in a nested router hears didPop when its host route is popped', (tester) async {
    final router = await _pumpApp(tester, [
      AutoRoute(path: '/', page: _awarePage('Home')),
      AutoRoute(
        path: '/a',
        page: _stackHost('A'),
        children: [AutoRoute(path: '', page: _awarePage('B'))],
      ),
    ]);
    router.push(const _Route('A'));
    await tester.pumpAndSettle();
    expect(_events, ['Home.didPushNext', 'B.didPush']);

    _events.clear();
    router.pop();
    await tester.pumpAndSettle();
    expect(_events, ['Home.didPopNext', 'B.didPop']);
  });
}
