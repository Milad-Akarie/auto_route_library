import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// replaceAll from the third page of a stack leaves only the new page.
// https://github.com/Milad-Akarie/auto_route_library/issues/2008
// Headless test: auto_route/test/simple_router/replace_all_from_deep_stack_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('MenuRoute'), path: '/', initial: true),
        AutoRoute(page: _page('RecordRoute'), path: '/record'),
        AutoRoute(page: _page('FormRoute'), path: '/form'),
        AutoRoute(page: _page('LoginRoute'), path: '/login'),
      ],
    );
  });

  // Steps: push RecordRoute and FormRoute over MenuRoute, then call
  // replaceAll([LoginRoute()]) from FormRoute.
  // Should: LoginRoute is the only page, not a blank screen.
  testWidgets('replaceAll from the third page leaves only the new page', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('RecordRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const PageRouteInfo('FormRoute')));
    await tester.pumpAndSettle();

    unawaited(
      tester.element(find.text('FormRoute')).router.replaceAll([
        const PageRouteInfo('LoginRoute'),
      ]),
    );
    await tester.pumpAndSettle();
    expect(router.stack.map((p) => p.name), ['LoginRoute']);
    expectCurrentPage(router, 'LoginRoute');
    await expectBrowserUrl('/login');
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(appBar: AppBar(), body: Text(name)),
);
