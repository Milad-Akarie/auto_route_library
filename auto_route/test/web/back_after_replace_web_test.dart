@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/flutter/flutter/issues/159200
  // In go_router, the browser back button went to a page that a redirect had
  // already replaced.
  // Steps: open HomeRoute, push LinkRoute, which replaces itself with
  // ChildRoute at once, then press the browser back button.
  // Should: back shows HomeRoute at '/', not LinkRoute.
  testWidgets(
    'On web, the browser back button skips a page that replaced itself (flutter/flutter#159200)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
          ),
          NamedRouteDef(
            name: 'LinkRoute',
            path: '/link',
            builder: (context, _) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => context.router.replace(const NamedRoute('ChildRoute')),
              );
              return const Scaffold(body: Text('LinkRoute'));
            },
          ),
          NamedRouteDef(
            name: 'ChildRoute',
            path: '/child',
            builder: (_, _) => const Scaffold(body: Text('ChildRoute')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router.config()),
      );
      await settleBrowser(tester);

      unawaited(router.pushPath('/link'));
      await settleBrowser(tester);
      expect(find.text('ChildRoute'), findsOneWidget);
      expect(browserPath, '/child');

      await pressBrowserBack(tester);

      expect(browserPath, '/');
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(find.text('LinkRoute'), findsNothing);
      expect(router.stack.map((e) => e.routeData.name), ['HomeRoute']);
    },
  );
}
