import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'centered_named_page.dart';
import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/106204
  // initialLocation '/auth/login' overrode a deep link to '/second' that the
  // platform sent at start. In auto_route the first link from the platform
  // is what opens; the router's routes decide where an empty one goes.
  testWidgets(
    'A deep link at start opens its page, not the initial route (flutter/flutter#106204)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'LoginRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const CenteredNamedPage('LoginRoute'),
          ),
          NamedRouteDef(
            name: 'SecondRoute',
            path: '/second',
            builder: (_, _) => const CenteredNamedPage('SecondRoute'),
          ),
        ],
      );
      await pumpRouterApp(tester, router, initialLink: '/second');
      expect(find.text('SecondRoute'), findsOneWidget);
      expect(router.urlState.url, '/second');
    },
  );
}
