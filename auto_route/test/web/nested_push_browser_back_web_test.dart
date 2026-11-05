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

  // https://github.com/Milad-Akarie/auto_route_library/issues/1593
  // Reported on web: after pushing a page in a nested router, the browser's
  // back button threw "A NestedStackRouter was used after being disposed".
  // Steps: a router at '/' holds DiscoverRoute 'discover' (initial) and
  // UserDetailRoute 'users/:id'; push UserDetailRoute from DiscoverRoute,
  // press the browser's back button, and do it again.
  // Should: no error; DiscoverRoute shows at '/discover' each time.
  testWidgets(
    'On web, the back button after a push in a nested router returns without an error',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef.shell(
            name: 'AuthenticatedRoute',
            path: '/',
            children: [
              NamedRouteDef(
                name: 'DiscoverRoute',
                path: 'discover',
                initial: true,
                builder: (_, _) => const Scaffold(body: Text('DiscoverRoute')),
              ),
              NamedRouteDef(
                name: 'UserDetailRoute',
                path: 'users/:id',
                builder: (_, data) =>
                    Scaffold(body: Text('user ${data.params.getString('id')}')),
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      await settleBrowser(tester);

      for (final id in ['7', '8']) {
        final discover = tester.element(find.text('DiscoverRoute')).router;
        unawaited(
          discover.push(NamedRoute('UserDetailRoute', params: {'id': id})),
        );
        await settleBrowser(tester);
        expect(find.text('user $id'), findsOneWidget);
        expect(browserPath, '/users/$id');

        await pressBrowserBack(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('DiscoverRoute'), findsOneWidget);
        expect(browserPath, '/discover');
      }
    },
  );
}
