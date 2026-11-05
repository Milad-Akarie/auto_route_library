import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Reads the route data above the navigator of each route pushed, as an
// analytics observer might, and records what it found or the error.
class _ReadingObserver extends AutoRouterObserver {
  final found = <String>[];

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) {
    if (route is! PopupRoute) return;
    try {
      found.add(RouteData.of(route.navigator!.context).name);
      // RouteData.of reports a missing scope with this error.
      // ignore: avoid_catching_errors
    } on FlutterError catch (e) {
      found.add('error: ${e.message.split('\n').firstOrNull ?? ''}');
    }
  }
}

void main() {
  late _ReadingObserver rootObserver;
  late _ReadingObserver shellObserver;
  late RootStackRouter router;

  setUp(() {
    rootObserver = _ReadingObserver();
    shellObserver = _ReadingObserver();
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: PageInfo(
            'ShellRoute',
            builder: (_) => AutoRouter(navigatorObservers: () => [shellObserver], inheritNavigatorObservers: false),
          ),
          path: '/',
          initial: true,
          children: [AutoRoute(page: _menuPage, path: '', initial: true)],
        ),
      ],
    );
  });

  Future<void> openAndPickFromMenu(WidgetTester tester, {required bool useRootNavigator}) async {
    await tester.tap(find.text(useRootNavigator ? 'Root menu' : 'Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Item'), findsOneWidget);
    await tester.tap(find.text('Item'));
    await tester.pumpAndSettle();
    expect(find.text('Item'), findsNothing);
  }

  // flutter/flutter#159593: in go_router, an observer of a nested navigator
  // that read the router's state from route.navigator.context in didPush
  // hung the app once showMenu pushed its popup route. In auto_route the
  // same read, RouteData.of, finds the page holding the nested navigator.
  // Steps: open a menu on a page of a nested router, pick its item.
  // Should: the menu opens and closes, and the observer reads ShellRoute.
  testWidgets('An observer reading RouteData when a menu opens in a nested router finds its host page', (tester) async {
    await pumpRouterApp(tester, router, observers: () => [rootObserver]);
    await openAndPickFromMenu(tester, useRootNavigator: false);
    expect(shellObserver.found, ['ShellRoute']);
    expect(rootObserver.found, isEmpty);
  });

  // flutter/flutter#159593, the root navigator: nothing above it holds
  // RouteData, so the read throws a FlutterError the observer can catch,
  // and the menu works.
  testWidgets('An observer reading RouteData when a menu opens on the root navigator gets an error it can catch', (
    tester,
  ) async {
    await pumpRouterApp(tester, router, observers: () => [rootObserver]);
    await openAndPickFromMenu(tester, useRootNavigator: true);
    expect(rootObserver.found.singleOrNull, startsWith('error: RouteData operation requested with a context'));
    expect(shellObserver.found, isEmpty);
  });
}

final _menuPage = PageInfo(
  'MenuRoute',
  builder: (_) => Builder(
    builder: (context) => Scaffold(
      body: Column(
        children: [
          for (final (label, root) in [('Menu', false), ('Root menu', true)])
            TextButton(
              onPressed: () => showMenu<void>(
                context: context,
                position: .fill,
                useRootNavigator: root,
                items: [const PopupMenuItem(child: Text('Item'))],
              ),
              child: Text(label),
            ),
        ],
      ),
    ),
  ),
);
