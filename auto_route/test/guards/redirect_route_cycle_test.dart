import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../centered_named_page.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/104441
  // Two redirects that point at each other, '/a' to '/b' and '/b' to '/a',
  // failed an assertion in go_router. In auto_route they recursed until the
  // stack overflowed. Steps: on '/', push '/a'. The push must fail with an
  // error that names both paths, and the stack stays as it was.
  testWidgets(
    'RedirectRoutes pointing at each other report the loop (flutter/flutter#104441)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const CenteredNamedPage('HomeRoute'),
          ),
          RedirectRoute(path: '/a', redirectTo: '/b'),
          RedirectRoute(path: '/b', redirectTo: '/a'),
        ],
      );
      await pumpRouterApp(tester, router);

      expect(
        () => router.pushPath('/a'),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('Redirect loop'), contains('/a'), contains('/b')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), ['HomeRoute']);
      expectCurrentPage(router, 'HomeRoute');
    },
  );
}
