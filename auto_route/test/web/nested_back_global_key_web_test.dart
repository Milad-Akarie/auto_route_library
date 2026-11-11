@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  late RootStackRouter router;
  setUp(() async {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: _shell('LayoutRoute'),
          children: [
            AutoRoute(
              path: 'dashboard',
              page: _page('DashboardRoute'),
              initial: true,
            ),
            AutoRoute(path: 'links', page: _page('LinksRoute')),
            AutoRoute(path: 'settings', page: _page('SettingsRoute')),
          ],
        ),
      ],
    );
    await rewindBrowserHistory();
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/924
  // On web, a layout page holds a nested router over dashboard, links and
  // settings, with an AutoRouteObserver (the report's title observer). Open
  // links, then settings, then press the browser's back button. (The report
  // used replace(), which adds no history entry, so back would leave the app.)
  // Reported: "A GlobalKey was used multiple times inside one widget's child
  // list" (the nested Navigator's key). Should: no exception, and a page of the
  // layout shows with an address that matches it.
  testWidgets(
    'On web, back after opening pages in a nested router throws nothing',
    (tester) async {
      await pumpRouterConfigApp(
        tester,
        router.config(navigatorObservers: () => [AutoRouteObserver()]),
      );
      await settleBrowser(tester);
      expect(find.text('DashboardRoute'), findsOneWidget);

      final nested = router.innerRouterOf<StackRouter>('LayoutRoute')!;
      unawaited(nested.push(const _Route('LinksRoute')));
      await settleBrowser(tester);
      expect(find.text('LinksRoute'), findsOneWidget);
      unawaited(nested.push(const _Route('SettingsRoute')));
      await settleBrowser(tester);
      expect(find.text('SettingsRoute'), findsOneWidget);

      await pressBrowserBack(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(Text), findsOneWidget);
      final shown = router
          .innerRouterOf<StackRouter>('LayoutRoute')!
          .current
          .name;
      expect(find.text(shown), findsOneWidget);
      expect(browserPath, router.urlState.uri.toString());
    },
  );
}

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

PageInfo _shell(String name) => .new(name, builder: (_) => const AutoRouter());
