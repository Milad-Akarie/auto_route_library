import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A pushed route with children keeps its fragment in the url.
// Found by DCM's avoid-incomplete-copy-with while moving the package to
// very_good_analysis; no upstream issue.
// Headless test: auto_route/test/nested_route_fragment_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('nested route fragment', () {
    // Steps: push BooksRoute with its child BookListRoute and the fragment top.
    // Should: the page shows, and the url is /books#top.
    testWidgets('a pushed route with children keeps its fragment in the url', (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const Text('HomeRoute'),
            ),
          ),
          AutoRoute(
            path: '/books',
            page: PageInfo('BooksRoute', builder: (_) => const AutoRouter()),
            children: [
              AutoRoute(
                path: '',
                page: PageInfo(
                  'BookListRoute',
                  builder: (_) => const Scaffold(
                    body: SafeArea(child: Text('BookListRoute')),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(
        router.push(
          const NamedRoute(
            'BooksRoute',
            children: [NamedRoute('BookListRoute')],
            fragment: 'top',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BookListRoute'), findsOneWidget);
      expect(router.urlState.url, '/books#top');
      await expectBrowserUrl('/books#top');
    });
  });
}
