import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Guard for https://github.com/Milad-Akarie/auto_route_library/issues/1788
// Setup, as in the report (auto_route 7.8.4, Android 14, with
// enableOnBackInvokedCallback): cupertino routes by default, fading custom
// routes, a welcome page first and a login page, then an authorized page
// whose nested router starts on a home page and holds an activity page.
// Steps: push the login page and press back; then show the authorized page
// alone, push the activity page and press back twice. Also with the
// predictive back gesture.
// Happened: back on any page closed the app, because Flutter told Android
// it doesn't handle back.
// Should: back pops the page on top, and Flutter tells Android it handles
// back while there's a page to pop. On the authorized home page there's
// none, and Android closes the app, as it does for any app's first page.
// Already works on dev, for both ways back, including in the nested router,
// the case a comment reports on 10.1.2.
void main() {
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

  final backs = {'system back': systemBack, 'the predictive back gesture': predictiveBack};

  for (final MapEntry(key: name, value: back) in backs.entries) {
    testWidgets('$name should pop the page on top, flat or nested, and keep the app open', (tester) async {
      final frameworkHandlesBack = FrameworkHandlesBackRecorder()..listen(tester);
      await tester.pumpWidget(MaterialApp.router(theme: androidTheme, routerConfig: router.config()));
      await tester.pumpAndSettle();
      expect(frameworkHandlesBack.last, isFalse);

      router.push(const _Route('LoginRoute'));
      await tester.pumpAndSettle();
      expect(frameworkHandlesBack.last, isTrue);
      await back(tester);
      expectTopPage(router, 'WelcomeRoute');

      router.replaceAll([const _Route('AuthorizedRoute')]);
      await tester.pumpAndSettle();
      expectTopPage(router, 'HomeRoute');
      router.innerRouterOf<StackRouter>('AuthorizedRoute')!.push(const _Route('ActivityRoute'));
      await tester.pumpAndSettle();
      expect(frameworkHandlesBack.last, isTrue);

      await back(tester);
      expectTopPage(router, 'HomeRoute');
      expect(frameworkHandlesBack.last, isFalse);
    }, skip: kIsWeb); // Android only: on web Flutter never tells the platform whether it handles back.
  }
}

CustomRoute _fade(PageInfo page, String path, {bool initial = false}) => CustomRoute(
      page: page,
      path: path,
      initial: initial,
      transitionsBuilder: TransitionsBuilders.fadeIn,
      duration: const Duration(milliseconds: 200),
    );

PageInfo _page(String name) => PageInfo(name, builder: (_) => Scaffold(body: Text(name)));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}
