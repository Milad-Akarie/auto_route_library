import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'centered_named_page.dart';
import 'router_test_utils.dart';

void main() {
  final routes = [
    NamedRouteDef(
      name: 'HomeRoute',
      path: '/',
      builder: (_, _) => const CenteredNamedPage('HomeRoute'),
    ),
    RedirectRoute(
      path: '/auth/register/phone/verify',
      redirectTo: '/auth/register',
    ),
    NamedRouteDef(
      name: 'RegisterRoute',
      path: '/auth/register',
      builder: (_, _) => const CenteredNamedPage('RegisterRoute'),
      children: [
        NamedRouteDef(
          name: 'PhoneRoute',
          path: 'phone',
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'VerifyRoute',
              path: 'verify',
              builder: (_, _) => const CenteredNamedPage('VerifyRoute'),
            ),
          ],
        ),
      ],
    ),
    RedirectRoute(path: '/old', redirectTo: '/three/four'),
    NamedRouteDef(
      name: 'ThreeRoute',
      path: '/three',
      builder: (_, _) => const CenteredNamedPage('ThreeRoute'),
    ),
    NamedRouteDef(
      name: 'FourRoute',
      path: '/three/four',
      builder: (_, _) => const CenteredNamedPage('FourRoute'),
    ),
  ];

  // https://github.com/flutter/flutter/issues/99097
  // A deep link to a child of a route, '/auth/register/phone/verify', is
  // redirected to its ancestor '/auth/register'. The app should show only the
  // target and the url should read '/auth/register', with none of the
  // children the first path matched built.
  testWidgets(
    'A redirect from a deep child to its ancestor leaves only the ancestor (flutter/flutter#99097)',
    (tester) async {
      final router = RootStackRouter.build(routes: routes);
      await pumpRouterApp(
        tester,
        router,
        initialLink: '/auth/register/phone/verify',
      );
      // '/' is a prefix of every link, so HomeRoute sits below the target.
      expect(router.stack.map((e) => e.name), ['HomeRoute', 'RegisterRoute']);
      expect(router.urlState.url, '/auth/register');
      expect(find.text('PhoneRoute'), findsNothing);
      expect(find.text('VerifyRoute'), findsNothing);
    },
  );

  // https://github.com/flutter/flutter/issues/99111
  // https://github.com/flutter/flutter/issues/107712
  // A route redirected to '/three/four' and then popped went back past the
  // page it redirected to (two pages gone at once), or didn't go back at all.
  // Steps: on '/', push '/old' (a redirect to '/three/four'), pop. One pop
  // should remove FourRoute only and show HomeRoute again.
  testWidgets(
    'Popping a page opened through a redirect removes that page only (flutter/flutter#99111)',
    (tester) async {
      final router = RootStackRouter.build(routes: routes);
      await pumpRouterApp(tester, router);

      unawaited(router.pushPath('/three'));
      await tester.pumpAndSettle();
      unawaited(router.pushPath('/old'));
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), [
        'HomeRoute',
        'ThreeRoute',
        'FourRoute',
      ]);
      expect(router.urlState.url, '/three/four');

      router.pop();
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), ['HomeRoute', 'ThreeRoute']);
      expect(router.urlState.url, '/three');

      router.pop();
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), ['HomeRoute']);
      expect(router.urlState.url, '/');
    },
  );

  // https://github.com/flutter/flutter/issues/101366
  // Several redirects in a row, '/a' to '/b' to '/three/four': each is
  // followed in order, and the page opens once.
  testWidgets(
    'Chained redirects end on the last target, once (flutter/flutter#101366)',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const CenteredNamedPage('HomeRoute'),
          ),
          RedirectRoute(path: '/a', redirectTo: '/b'),
          RedirectRoute(path: '/b', redirectTo: '/target'),
          NamedRouteDef(
            name: 'TargetRoute',
            path: '/target',
            builder: (_, _) => const CenteredNamedPage('TargetRoute'),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(router.pushPath('/a'));
      await tester.pumpAndSettle();
      expect(router.stack.map((e) => e.name), ['HomeRoute', 'TargetRoute']);
      expect(router.urlState.url, '/target');
    },
  );
}
