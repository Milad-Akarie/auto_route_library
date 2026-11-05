import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// Each call an _AwarePage gets from its AutoRouteObserver, as '<route name>.<call>'.
final _events = <String>[];

class _AwarePage extends StatefulWidget {
  const new({this.child});
  final Widget? child;

  @override
  State<_AwarePage> createState() => _AwarePageState();
}

class _AwarePageState extends State<_AwarePage>
    with AutoRouteAwareStateMixin<_AwarePage> {
  late final String _name = context.routeData.name;

  @override
  Widget build(BuildContext context) => widget.child ?? Text(_name);

  @override
  void didPush() => _events.add('$_name.didPush');

  @override
  void didPop() => _events.add('$_name.didPop');

  @override
  void didPushNext() => _events.add('$_name.didPushNext');

  @override
  void didPopNext() => _events.add('$_name.didPopNext');

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) =>
      _events.add('$_name.didInitTabRoute');

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) =>
      _events.add('$_name.didChangeTabRoute');
}

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}

PageInfo _awarePage(String name) =>
    .new(name, builder: (_) => const _AwarePage());

PageInfo _awareStackHost(String name) =>
    .new(name, builder: (_) => const _AwarePage(child: AutoRouter()));

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1028
  // Setup, as reported: a page hosts an AutoTabsRouter with two tabs, each a
  // stack with AutoRouteAware pages, and the observer is an AutoRouteObserver.
  // Steps: open the first tab, push another page over its page, pop it, then
  // switch to the second tab and back.
  // Reported: the page under the pushed one heard none of it, and the tab
  // events came only when subscribing to the tabs router's own route data.
  // Should: the covered page hears didPushNext and didPopNext, and a tab's
  // page hears the tab events of its own tab (as the observer sends them to the
  // subscribers of the tab's route).
  testWidgets(
    'Pages in tabs hear covers inside their tab, and a tab page hears its tab events',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo(
              'TabsHost',
              builder: (_) => const _AwarePage(
                child: AutoTabsRouter(routes: [_Route('TabA'), _Route('TabB')]),
              ),
            ),
            children: [
              AutoRoute(
                path: 'a',
                page: _awareStackHost('TabA'),
                children: [
                  AutoRoute(path: '', page: _awarePage('A1')),
                  AutoRoute(path: 'two', page: _awarePage('A2')),
                ],
              ),
              AutoRoute(
                path: 'b',
                page: _awareStackHost('TabB'),
                children: [AutoRoute(path: '', page: _awarePage('B1'))],
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(navigatorObservers: () => [AutoRouteObserver()]),
      );
      expect(find.text('A1'), findsOneWidget);

      _events.clear();
      unawaited(
        router
            .innerRouterOf<TabsRouter>('TabsHost')!
            .innerRouterOf<StackRouter>('TabA')!
            .push(const _Route('A2')),
      );
      await tester.pumpAndSettle();
      expect(_events, ['A1.didPushNext', 'A2.didPush']);

      _events.clear();
      router
          .innerRouterOf<TabsRouter>('TabsHost')!
          .innerRouterOf<StackRouter>('TabA')!
          .pop();
      await tester.pumpAndSettle();
      expect(_events, ['A2.didPop', 'A1.didPopNext']);

      _events.clear();
      router.innerRouterOf<TabsRouter>('TabsHost')!.setActiveIndex(1);
      await tester.pumpAndSettle();
      expect(find.text('B1'), findsOneWidget);
      expect(_events, contains('TabB.didInitTabRoute'));

      _events.clear();
      router.innerRouterOf<TabsRouter>('TabsHost')!.setActiveIndex(0);
      await tester.pumpAndSettle();
      expect(_events, contains('TabA.didChangeTabRoute'));
    },
  );
}
