import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// replaceAll listing an open parent and then its child shows the child.
// https://github.com/Milad-Akarie/auto_route_library/issues/1586
// Headless test: auto_route/test/replace_all_open_parent_child_test.dart
//
// Setup, as in the report: MainRoute at '/' with the children HomeRoute
// (where '' redirects) and SearchRoute. The app starts on MainRoute >
// HomeRoute.
// Steps: router.replaceAll([MainRoute(), SearchRoute()]).
// Reported: it did not work; later it failed Flutter's duplicate key
// assertion.
// Should: SearchRoute shows, with HomeRoute below it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('replaceAll parent then child', () {
    testWidgets('shows the child', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            initial: true,
            page: PageInfo('MainRoute', builder: (_) => const AutoRouter()),
            children: [
              RedirectRoute(path: '', redirectTo: 'home'),
              AutoRoute(path: 'home', page: _page('HomeRoute')),
              AutoRoute(path: 'search', page: _page('SearchRoute')),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      expect(find.text('HomeRoute'), findsOneWidget);

      unawaited(
        router.replaceAll(const [
          NamedRoute('MainRoute'),
          NamedRoute('SearchRoute'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('SearchRoute'), findsOneWidget);
      expectTopPage(router, 'SearchRoute');
      expect(
        router
            .innerRouterOf<StackRouter>('MainRoute')!
            .stack
            .map((page) => page.name),
        ['HomeRoute', 'SearchRoute'],
      );
    });
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
