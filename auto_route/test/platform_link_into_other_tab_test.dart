import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';
import 'universal_link_test.dart' show didSendPlatformLink;

// https://github.com/Milad-Akarie/auto_route_library/issues/2229
// Setup: the home page holds an AutoTabsRouter whose two tabs are shells, each
// with its own nested stack of two pages. The app uses router.delegate() with
// defaultRouteParser(), as the report does, and, as the report does, gives
// each tab's AutoRouter a navigator key of its own, made once and kept in a
// map. (The maintainer asked why the app does that, and no answer came.)
// Steps: open the app on the first tab, send the app to the background, then
// send the platform link '/tabs/b/b2' (a page in the other tab) while it is
// in the background, bring it back; then the same with '/tabs/a/a2' (back to
// the first tab).
// Reported: on Android 15+ the link raised "Duplicate GlobalKey detected" for
// a NavigatorState key.
// Should: no exception, and the linked page shows each time.
void main() {
  testWidgets(
    'A platform link into another tab raises no duplicate GlobalKey error',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            page: _page('TabsRoute', child: _tabs),
            path: '/tabs',
            initial: true,
            children: [
              AutoRoute(
                page: _page(
                  'TabARoute',
                  child: AutoRouter(navigatorKey: _keyA),
                ),
                path: 'a',
                initial: true,
                children: [
                  AutoRoute(page: _page('A1Route'), path: 'a1', initial: true),
                  AutoRoute(page: _page('A2Route'), path: 'a2'),
                ],
              ),
              AutoRoute(
                page: _page(
                  'TabBRoute',
                  child: AutoRouter(navigatorKey: _keyB),
                ),
                path: 'b',
                children: [
                  AutoRoute(page: _page('B1Route'), path: 'b1', initial: true),
                  AutoRoute(page: _page('B2Route'), path: 'b2'),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      expect(find.text('A1Route'), findsOneWidget);

      Future<void> expectLinkShows(String link, String page) async {
        await _setLifecycle(tester, [.inactive, .hidden, .paused]);
        await didSendPlatformLink(tester, link);
        await _setLifecycle(tester, [.hidden, .inactive, .resumed]);
        expect(tester.takeException(), isNull, reason: link);
        expect(find.text(page), findsOneWidget);
      }

      await expectLinkShows('/tabs/b/b2', 'B2Route');
      expect(_keyB.currentState, isNotNull, reason: 'the tab uses its key');
      await expectLinkShows('/tabs/a/a2', 'A2Route');
    },
  );
}

// The navigator keys of the tabs, as the report keeps them: made once.
final _keyA = GlobalKey<NavigatorState>(debugLabel: 'tab a');
final _keyB = GlobalKey<NavigatorState>(debugLabel: 'tab b');

/// Moves the app through [states] in order, as the platform does when the app
/// goes to the background or comes back.
Future<void> _setLifecycle(
  WidgetTester tester,
  List<AppLifecycleState> states,
) async {
  for (final state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
}

Widget get _tabs => AutoTabsRouter(
  routes: const [PageRouteInfo('TabARoute'), PageRouteInfo('TabBRoute')],
  builder: (context, child) => child,
);

PageInfo _page(String name, {Widget? child}) =>
    .new(name, builder: (_) => Scaffold(body: child ?? Text(name)));
