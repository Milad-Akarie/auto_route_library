import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// System back pops the page on top instead of closing the app.
// https://github.com/Milad-Akarie/auto_route_library/issues/1788
// Headless test: auto_route/test/android_back_in_app_test.dart
//
// Setup, as in the report: cupertino routes by default, fading custom
// routes, a welcome page first and a login page, then an authorized page
// whose nested router starts on a home page and holds an activity page.
// Steps: push the login page and press system back; then show the
// authorized page alone, push the activity page and press system back. On
// Android that goes through the activity, which Android calls only while
// Flutter says it handles back (see systemBack).
// Reported: back on any page closed the app.
// Should: back pops the page on top. On the authorized home page there's
// nothing left to pop, so Android would close the app there.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      defaultRouteType: const RouteType.cupertino(),
      routes: [
        _fade(_page('WelcomeRoute'), '/'),
        _fade(_page('LoginRoute'), '/login'),
        CustomRoute(
          page: PageInfo('AuthorizedRoute', builder: (_) => const AutoRouter()),
          path: '/authorized',
          transitionsBuilder: TransitionsBuilders.fadeIn,
          duration: const Duration(milliseconds: 200),
          children: [
            _fade(_page('HomeRoute'), 'home', initial: true),
            _fade(_page('ActivityRoute'), 'activity'),
          ],
        ),
      ],
    );
  });

  testWidgets(
    'system back pops the page on top, flat or nested, and keeps the app open',
    (tester) async {
      await pumpRouterApp(tester, router);

      unawaited(router.push(const _Route('LoginRoute')));
      await tester.pumpAndSettle();
      await systemBack(tester);
      expectTopPage(router, 'WelcomeRoute');

      unawaited(router.replaceAll([const _Route('AuthorizedRoute')]));
      await tester.pumpAndSettle();
      expectTopPage(router, 'HomeRoute');
      unawaited(
        router
            .innerRouterOf<StackRouter>('AuthorizedRoute')!
            .push(const _Route('ActivityRoute')),
      );
      await tester.pumpAndSettle();

      await systemBack(tester);
      expectTopPage(router, 'HomeRoute');
      expect(await androidSendsBackToFlutter(), anyOf(isNull, isFalse));
    },
  );
}

CustomRoute _fade(PageInfo page, String path, {bool initial = false}) => .new(
  page: page,
  path: path,
  initial: initial,
  transitionsBuilder: TransitionsBuilders.fadeIn,
  duration: const Duration(milliseconds: 200),
);

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const new(super.name);
}
