import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'named_page.dart';
import 'router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1662
  // Reported: a hot reload on a nested page went back to the initial route
  // of the parent router, DebugTab.
  // Steps: ToolsTab '/tools' holds an initial DebugTab router, itself with
  // an initial page, and a ComponentRouter whose initial page is
  // ComponentTemplateRoute; the router is created outside build. Open
  // '/tools/component', then hot reload.
  // Should: ComponentTemplateRoute stays, at the same url.
  testWidgets(
    'A hot reload keeps a nested page next to an initial sibling router',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'TempRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const NamedPage('TempRoute'),
          ),
          NamedRouteDef.shell(
            name: 'ToolsTab',
            path: '/tools',
            children: [
              NamedRouteDef.shell(
                name: 'DebugTab',
                path: 'debug',
                initial: true,
                children: [
                  NamedRouteDef(
                    name: 'DebugRoute',
                    path: 'debug',
                    initial: true,
                    builder: (_, _) => const NamedPage('DebugRoute'),
                  ),
                  NamedRouteDef(
                    name: 'LogHistoryRoute',
                    path: 'log',
                    builder: (_, _) => const NamedPage('LogHistoryRoute'),
                  ),
                ],
              ),
              NamedRouteDef.shell(
                name: 'ComponentRouter',
                path: 'component',
                children: [
                  NamedRouteDef(
                    name: 'ComponentTemplateRoute',
                    initial: true,
                    builder: (_, _) =>
                        const NamedPage('ComponentTemplateRoute'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.navigatePath('/tools/component'));
      await tester.pumpAndSettle();
      expect(find.text('ComponentTemplateRoute'), findsOneWidget);

      unawaited(tester.binding.reassembleApplication());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('ComponentTemplateRoute'), findsOneWidget);
      expect(find.text('DebugRoute'), findsNothing);
      expect(router.urlState.url, '/tools/component');
    },
  );
}
