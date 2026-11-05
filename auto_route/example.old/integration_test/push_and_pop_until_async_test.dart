import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// pushAndPopUntil removes the routes below the new page only once its guards
// let it through, on the stack as it is then. With scopedPopUntil: false it
// removes the routes of nested routers the same way, and a nested router whose
// shell goes keeps its page on screen under the new one.
// https://github.com/Milad-Akarie/auto_route_library/issues/1797
// Headless tests: auto_route/test/guards/push_and_pop_until_slow_guard_test.dart
// and auto_route/test/nested_router/push_and_pop_until_nested_test.dart.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Completer<bool> decision;
  late RootStackRouter router;
  setUp(() {
    decision = Completer<bool>();
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
        AutoRoute(page: _page('ARoute'), path: '/a'),
        AutoRoute(page: _page('BRoute'), path: '/b'),
        AutoRoute(
          page: _page('CRoute'),
          path: '/c',
          guards: [
            AutoRouteGuardCallback((resolver, _) async {
              if (await decision.future) {
                resolver.next();
              } else {
                resolver.reject();
              }
            }),
          ],
        ),
      ],
    );
  });

  List<String> names() =>
      router.stack.map((page) => page.routeData.name).toList();

  // Opens HomeRoute, ARoute and BRoute, then calls pushAndPopUntil(CRoute)
  // keeping HomeRoute, keeps its future in [pushedC] and waits while CRoute's
  // guard decides.
  late Future<Object?> pushedC;
  Future<void> pushCWhileGuardDecides(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('ARoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const PageRouteInfo('BRoute')));
    await tester.pumpAndSettle();

    pushedC = router.pushAndPopUntil(
      const PageRouteInfo('CRoute'),
      predicate: (route) => route.settings.name == 'HomeRoute',
    );
    await tester.pumpAndSettle();
    expect(names(), ['HomeRoute', 'ARoute', 'BRoute']);
    expectCurrentPage(router, 'BRoute');
  }

  // Steps: open HomeRoute, ARoute and BRoute, call pushAndPopUntil(CRoute)
  // keeping HomeRoute while CRoute's guard decides, pop BRoute, then let the
  // guard accept.
  // Should: nothing moves while the guard decides; then HomeRoute and CRoute
  // are left, and back goes to HomeRoute.
  testWidgets(
    'pushAndPopUntil waits for a slow guard, then removes the routes left',
    (tester) async {
      await pushCWhileGuardDecides(tester);
      unawaited(router.maybePop());
      await tester.pumpAndSettle();
      expect(names(), ['HomeRoute', 'ARoute']);

      decision.complete(true);
      await tester.pumpAndSettle();
      expect(names(), ['HomeRoute', 'CRoute']);
      expectCurrentPage(router, 'CRoute');

      unawaited(router.maybePop());
      await tester.pumpAndSettle();
      expectCurrentPage(router, 'HomeRoute');
    },
  );

  // Steps: open HomeRoute, ARoute and BRoute, call pushAndPopUntil(CRoute)
  // keeping HomeRoute, then let CRoute's guard reject.
  // Should: the stack stays as it was and the push completes with null.
  testWidgets(
    'pushAndPopUntil rejected by a slow guard leaves the stack as it was',
    (tester) async {
      await pushCWhileGuardDecides(tester);

      decision.complete(false);
      expect(await pushedC, isNull);
      await tester.pumpAndSettle();
      expect(names(), ['HomeRoute', 'ARoute', 'BRoute']);
      expectCurrentPage(router, 'BRoute');
    },
  );

  group('from a nested router', () {
    late RootStackRouter router;
    late List<String> observed;
    setUp(() {
      observed = [];
      // Cupertino pages slide on every platform, web included.
      router = RootStackRouter.build(
        defaultRouteType: const RouteType.cupertino(),
        routes: [
          AutoRoute(page: _page('HomeRoute'), path: '/', initial: true),
          AutoRoute(
            page: const EmptyShellRoute('ShellRoute'),
            path: '/shell',
            children: [
              AutoRoute(page: _page('S1Route'), path: '', initial: true),
              AutoRoute(page: _page('S2Route'), path: 's2'),
            ],
          ),
          AutoRoute(page: _page('DoneRoute'), path: '/done'),
        ],
      );
    });

    List<String> namesOf(StackRouter router) =>
        router.stack.map((page) => page.routeData.name).toList();

    // Opens HomeRoute, then ShellRoute with S1Route and S2Route, calls
    // pushAndPopUntil(DoneRoute, scopedPopUntil: false) from the nested router
    // keeping the route named [kept], and returns the pages on screen in each
    // frame while DoneRoute slides in.
    Future<List<String>> pushDoneKeeping(
      WidgetTester tester,
      String kept,
    ) async {
      await pumpRouterApp(
        tester,
        router,
        navigatorObservers: () => [_NamesObserver(observed)],
      );
      unawaited(router.push(const PageRouteInfo('ShellRoute')));
      await tester.pumpAndSettle();
      final nested = router.innerRouterOf<StackRouter>('ShellRoute')!;
      unawaited(nested.push(const PageRouteInfo('S2Route')));
      await tester.pumpAndSettle();
      observed.clear();

      unawaited(
        nested.pushAndPopUntil(
          const PageRouteInfo('DoneRoute'),
          predicate: (route) => route.settings.name == kept,
          scopedPopUntil: false,
        ),
      );
      final frames = <String>[];
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        frames.add(
          [
            'HomeRoute',
            'S1Route',
            'S2Route',
            'DoneRoute',
          ].where((name) => find.text(name).evaluate().isNotEmpty).join(', '),
        );
      }
      await tester.pumpAndSettle();
      return frames;
    }

    // Steps: open HomeRoute, then ShellRoute with S1Route and S2Route, and
    // from the nested router call pushAndPopUntil(DoneRoute) keeping HomeRoute.
    // Should: S2Route stays under DoneRoute while it slides in, never a blank
    // shell; HomeRoute and DoneRoute are left, and back goes to HomeRoute.
    testWidgets(
      'keeping a root page removes the shell, with its page under the new one',
      (tester) async {
        final frames = await pushDoneKeeping(tester, 'HomeRoute');
        expect(
          frames.where(
            (frame) => !frame.startsWith('S2Route') && frame != 'DoneRoute',
          ),
          isEmpty,
          reason: '$frames',
        );
        expect(observed, ['push DoneRoute', 'remove ShellRoute']);
        expect(namesOf(router), ['HomeRoute', 'DoneRoute']);

        unawaited(router.maybePop());
        await tester.pumpAndSettle();
        expectCurrentPage(router, 'HomeRoute');
      },
    );

    // Steps: open HomeRoute, then ShellRoute with S1Route and S2Route, and
    // from the nested router call pushAndPopUntil(DoneRoute) keeping S1Route.
    // Should: S2Route is removed, not animated out; back from DoneRoute shows
    // S1Route in the shell, then HomeRoute.
    testWidgets('keeping a nested page removes the nested pages above it', (
      tester,
    ) async {
      final frames = await pushDoneKeeping(tester, 'S1Route');
      expect(
        frames.where((frame) => frame.contains('S2Route')),
        isEmpty,
        reason: '$frames',
      );
      expect(observed, containsAll(['push DoneRoute', 'remove S2Route']));
      expect(observed.where((event) => event.startsWith('pop')), isEmpty);
      expect(namesOf(router), ['HomeRoute', 'ShellRoute', 'DoneRoute']);

      unawaited(router.maybePop());
      await tester.pumpAndSettle();
      expect(router.topRoute.name, 'S1Route');
      expect(find.text('S1Route'), findsOneWidget);
      unawaited(router.maybePop());
      await tester.pumpAndSettle();
      expectCurrentPage(router, 'HomeRoute');
    });
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);

class _NamesObserver extends AutoRouterObserver {
  new(this.events);

  final List<String> events;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('push ${route.settings.name}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('pop ${route.settings.name}');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      events.add('remove ${route.settings.name}');
}
