import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1819
  // Reported: in a nested router whose pages are CustomRoutes with
  // TransitionsBuilders.noTransition, the titles of the old and of the new
  // page show on top of each other for a moment when navigating between them.
  // Setup: a '/dashboard' CustomRoute (noTransition) with the children 'home'
  // and 'brands', both CustomRoutes with noTransition. The pages have no
  // background of their own.
  //
  // This is the answer in the comments: the old page stays in the stack until
  // the new route's transition has finished, which is its duration (300 ms by
  // default) even when the builder does not animate anything, so a page
  // without a background shows what is below it. A background, or
  // `duration: Duration.zero` on the CustomRoute, ends it.
  for (final (duration, overlaps) in [(null, true), (Duration.zero, false)]) {
    testWidgets('Navigating between noTransition pages with ${duration == null ? 'the default' : 'a zero'} duration '
        '${overlaps ? 'keeps' : 'does not keep'} the old page on screen', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          CustomRoute<dynamic>(
            page: _dashboardPage,
            path: '/dashboard',
            transitionsBuilder: TransitionsBuilders.noTransition,
            children: [
              CustomRoute<dynamic>(
                page: _page('Home'),
                path: 'home',
                initial: true,
                transitionsBuilder: TransitionsBuilders.noTransition,
                duration: duration,
              ),
              CustomRoute<dynamic>(
                page: _page('Brands'),
                path: 'brands',
                transitionsBuilder: TransitionsBuilders.noTransition,
                duration: duration,
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(tester, router.config(deepLinkBuilder: (_) => const DeepLink.path('/dashboard/home')));
      expect(find.text('Home'), findsOneWidget);

      router.navigatePath('/dashboard/brands');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Brands'), findsOneWidget);
      expect(find.text('Home'), overlaps ? findsOneWidget : findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
    });
  }
}

final _dashboardPage = PageInfo('Dashboard', builder: (_) => const Scaffold(body: AutoRouter()));

// A page without a background, like the ones in the report.
PageInfo _page(String name) => .new(
  name,
  builder: (_) => Align(alignment: Alignment.topLeft, child: Text(name)),
);
