import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Each call an _AwarePage gets from its AutoRouteObserver, as '<route
// name>.<call>'.
final _events = <String>[];

class _AwarePage extends StatefulWidget {
  const new();

  @override
  State<_AwarePage> createState() => _AwarePageState();
}

class _AwarePageState extends State<_AwarePage>
    with AutoRouteAwareStateMixin<_AwarePage> {
  late final String _name = context.routeData.name;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text(context.routeData.name));

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
  const new(super.name);
}

PageInfo _awarePage(String name) =>
    .new(name, builder: (_) => const _AwarePage());

PageInfo _stackHost(String name) =>
    .new(name, builder: (_) => const AutoRouter());

/// Shows [routes] with a fresh [AutoRouteObserver] for each router, as the
/// README asks, then clears the calls the first pages got.
///
/// With [deepLink], the app opens there and the calls its pages got are kept.
Future<RootStackRouter> _pumpApp(
  WidgetTester tester,
  List<AutoRoute> routes, {
  String? deepLink,
}) async {
  final router = RootStackRouter.build(routes: routes);
  _events.clear();
  await pumpRouterConfigApp(
    tester,
    router.config(
      navigatorObservers: () => [AutoRouteObserver()],
      deepLinkBuilder: (link) =>
          deepLink == null ? link : DeepLink.path(deepLink),
    ),
  );
  if (deepLink == null) _events.clear();
  return router;
}

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1954
  // Steps: route A hosts a nested router showing route B, both with
  // AutoRouteAwareStateMixin. Push route C at the root, then pop it.
  // Happens: A's didPushNext and didPopNext fire, B's never do.
  // Should: B hears both, since it is the page covered and shown again.
  testWidgets(
    'A page in a nested router hears a root route cover and uncover its host',
    (tester) async {
      final router = await _pumpApp(tester, [
        AutoRoute(
          path: '/',
          page: _stackHost('A'),
          children: [AutoRoute(path: '', page: _awarePage('B'))],
        ),
        AutoRoute(path: '/c', page: _awarePage('C')),
      ]);

      unawaited(router.push(const _Route('C')));
      await tester.pumpAndSettle();
      expect(_events, ['B.didPushNext', 'C.didPush']);

      _events.clear();
      router.pop();
      await tester.pumpAndSettle();
      expect(_events, ['C.didPop', 'B.didPopNext']);
    },
  );

  // Same as above with two pages in the nested router: only the one on top
  // shows inside the host, so only that one hears its host covered.
  testWidgets(
    'A page covered inside its nested router is not told again when the host '
    'is covered',
    (tester) async {
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
      unawaited(
        router.innerRouterOf<StackRouter>('A')!.push(const _Route('B2')),
      );
      await tester.pumpAndSettle();
      expect(_events, ['B1.didPushNext', 'B2.didPush']);

      _events.clear();
      unawaited(router.push(const _Route('C')));
      await tester.pumpAndSettle();
      expect(_events, ['B2.didPushNext', 'C.didPush']);

      _events.clear();
      router.pop();
      await tester.pumpAndSettle();
      expect(_events, ['C.didPop', 'B2.didPopNext']);
    },
  );

  // https://github.com/Milad-Akarie/auto_route_library/issues/2306
  // Steps: AppRoute hosts tabs [Dashboard, Settings]; the Settings tab hosts
  // a nested router showing Something, a page with AutoRouteAware. Open the
  // Settings tab, push BottomSheetRoute, a CustomRoute that builds a
  // ModalBottomSheetRoute, on the root router, then close the sheet.
  // Happened: Something heard the sheet open only when the sheet was declared
  // in its own router; declared at the root, it heard neither open nor close.
  // Should: Something gets didPushNext, then didPopNext; the inactive
  // Dashboard tab hears nothing. The #1954 fix covers this.
  testWidgets(
    'A page in a tab hears a root bottom sheet open and close over it',
    (tester) async {
      final router = await _pumpApp(tester, [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'AppRoute',
            builder: (_) => const AutoTabsRouter(
              routes: [_Route('Dashboard'), _Route('Settings')],
            ),
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
        CustomRoute(
          path: '/bottom-sheet',
          page: PageInfo(
            'BottomSheetRoute',
            builder: (_) => const Text('sheet'),
          ),
          customRouteBuilder: <T>(context, child, page) =>
              ModalBottomSheetRoute<T>(
                settings: page,
                isScrollControlled: true,
                builder: (_) => child,
              ),
        ),
      ]);
      router.innerRouterOf<TabsRouter>('AppRoute')!.setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(find.text('Something'), findsOneWidget);

      _events.clear();
      unawaited(router.root.push(const _Route('BottomSheetRoute')));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget);
      expect(_events, ['Something.didPushNext']);

      _events.clear();
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing);
      expect(_events, ['Something.didPopNext']);
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1863
  // The report gives no setup; this is the one where didPop never fired on
  // dev: the page is inside a nested router and its host route is popped.
  // Steps: Home, then route A that hosts a nested router showing route B, all
  // with AutoRouteAwareStateMixin. Pop A.
  // Happens: B gets didPush when it shows, but never didPop.
  // Should: B gets didPop, as a page popped in its own router does.
  testWidgets(
    'A page in a nested router hears didPop when its host route is popped',
    (tester) async {
      final router = await _pumpApp(tester, [
        AutoRoute(path: '/', page: _awarePage('Home')),
        AutoRoute(
          path: '/a',
          page: _stackHost('A'),
          children: [AutoRoute(path: '', page: _awarePage('B'))],
        ),
      ]);
      unawaited(router.push(const _Route('A')));
      await tester.pumpAndSettle();
      expect(_events, ['Home.didPushNext', 'B.didPush']);

      _events.clear();
      router.pop();
      await tester.pumpAndSettle();
      expect(_events, ['B.didPop', 'Home.didPopNext']);
    },
  );

  // Reproduces https://github.com/flutter/flutter/issues/26902 in auto_route.
  // Steps: Home and B both have AutoRouteAwareStateMixin. Push B, then pop it.
  // Happened: Home heard didPopNext before B heard didPop, the reverse of a
  // push, where the page covered hears didPushNext before the new page hears
  // didPush. An app that flips a flag on each call ended with B's value.
  // Should: the page that leaves hears first, then the page that shows again.
  testWidgets(
    'Popping a page tells it didPop before the page under it hears didPopNext',
    (tester) async {
      final router = await _pumpApp(tester, [
        AutoRoute(path: '/', page: _awarePage('Home')),
        AutoRoute(path: '/b', page: _awarePage('B')),
      ]);
      unawaited(router.push(const _Route('B')));
      await tester.pumpAndSettle();
      expect(_events, ['Home.didPushNext', 'B.didPush']);

      _events.clear();
      router.pop();
      await tester.pumpAndSettle();
      expect(_events, ['B.didPop', 'Home.didPopNext']);
    },
  );

  // Reproduces https://github.com/flutter/flutter/issues/70272 in auto_route.
  // Steps: Home and B both have AutoRouteAwareStateMixin. Open the app on the
  // deep link /b, which stacks B on Home at once, then pop B.
  // Happened: Home heard didPush only. The navigator reported B's push before
  // Home's state existed to subscribe, so Home never heard didPushNext,
  // though B covers it; an app pausing work on didPushNext kept it running.
  // Should: Home hears didPush, then didPushNext, since B covers it.
  testWidgets('A page built under another by a deep link hears didPushNext', (
    tester,
  ) async {
    final router = await _pumpApp(tester, [
      AutoRoute(path: '/', page: _awarePage('Home')),
      AutoRoute(path: '/b', page: _awarePage('B')),
    ], deepLink: '/b');
    expectTopPage(router, 'B');
    expect(
      _events,
      unorderedEquals(['Home.didPush', 'Home.didPushNext', 'B.didPush']),
    );
    expect(
      _events.indexOf('Home.didPush'),
      lessThan(_events.indexOf('Home.didPushNext')),
    );

    _events.clear();
    router.pop();
    await tester.pumpAndSettle();
    expect(_events, ['B.didPop', 'Home.didPopNext']);
  });

  // Same as above with Home hosting a nested router that shows Child: Child
  // is on top of its own router, but its host is covered at the root.
  testWidgets(
    'A page in a nested router built under a deep link hears didPushNext',
    (tester) async {
      await _pumpApp(tester, [
        AutoRoute(
          path: '/',
          page: _stackHost('Home'),
          children: [AutoRoute(path: '', page: _awarePage('Child'))],
        ),
        AutoRoute(path: '/b', page: _awarePage('B')),
      ], deepLink: '/b');
      expect(
        _events,
        unorderedEquals(['Child.didPush', 'Child.didPushNext', 'B.didPush']),
      );
    },
  );
}
