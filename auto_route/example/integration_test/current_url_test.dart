import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// currentUrl keeps the characters that would change its meaning encoded.
// https://github.com/Milad-Akarie/auto_route_library/issues/1925
// Headless test: auto_route/test/current_url_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _RedirectingRoute.pageFor('RandomRoute'), path: '/random-page', initial: true),
        AutoRoute(page: _RedirectingRoute.pageFor('FirstRoute'), path: '/first-page'),
        AutoRoute(page: _RedirectingRoute.pageFor('SecondRoute'), path: '/second-page'),
      ],
    );
  });

  // Steps: at '/random-page', replace the page with
  // FirstRoute(redirectTo: currentUrl), then with
  // SecondRoute(redirectTo: currentUrl), then open currentUrl.
  // Should: SecondRoute reads '/first-page?redirectTo=/random-page' each time,
  // and on web the address bar holds it encoded.
  testWidgets('currentUrl keeps a url passed in a query param intact', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/random-page');
    unawaited(router.replace(_RedirectingRoute('FirstRoute', redirectTo: router.currentUrl)));
    await tester.pumpAndSettle();
    unawaited(router.replace(_RedirectingRoute('SecondRoute', redirectTo: router.currentUrl)));
    await tester.pumpAndSettle();
    expect(router.currentUrl, '/second-page?redirectTo=/first-page?redirectTo%3D/random-page');
    expect(find.text('SecondRoute to /first-page?redirectTo=/random-page'), findsOneWidget);
    await expectBrowserUrl('/second-page?redirectTo=%2Ffirst-page%3FredirectTo%3D%2Frandom-page');

    unawaited(router.navigatePath(router.currentUrl));
    await tester.pumpAndSettle();
    expect(find.text('SecondRoute to /first-page?redirectTo=/random-page'), findsOneWidget);
  });
}

class _RedirectingRoute extends PageRouteInfo<void> {
  _RedirectingRoute(super.name, {required String redirectTo}) : super(rawQueryParams: {'redirectTo': redirectTo});

  static PageInfo pageFor(String name) => .new(
    name,
    builder: (data) => Text('$name to ${data.queryParams.optString('redirectTo')}'),
  );
}
