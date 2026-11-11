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
  setUp(rewindBrowserHistory);

  // flutter/flutter#110772: on web, the browser's back button with a drawer
  // open on the page cleared the url and left the page as it was.
  // Steps: pages P1, P2, P3, each a Scaffold with a drawer; open P3's drawer
  // and press the browser's back button.
  // Should: the drawer closes with P3, P2 shows, and the url is P2's.
  testWidgets(
    'The browser back button with a drawer open goes to the page before and '
    'keeps its url',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          for (final page in ['P1', 'P2', 'P3'])
            AutoRoute(
              path: page == 'P1' ? '/' : '/${page.toLowerCase()}',
              page: PageInfo(
                page,
                builder: (_) => Scaffold(
                  appBar: AppBar(),
                  drawer: const Drawer(child: Text('Drawer')),
                  body: Text(page),
                ),
              ),
            ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);
      unawaited(router.pushPath('/p2'));
      await settleBrowser(tester);
      unawaited(router.pushPath('/p3'));
      await settleBrowser(tester);
      tester.state<ScaffoldState>(find.byType(Scaffold).last).openDrawer();
      await settleBrowser(tester);
      expect(find.text('Drawer'), findsOneWidget);

      await pressBrowserBack(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Drawer'), findsNothing);
      expect(router.stack.map((page) => page.name), ['P1', 'P2']);
      expectCurrentPage(router, 'P2');
      expect(browserPath, '/p2');
    },
  );
}
