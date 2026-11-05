import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Urls and a match's fullPath are joined with '/' on every platform; on
// Windows they came out with '\', and '/' matched no route.
// https://github.com/flutter/flutter/issues/102710
// Headless test: auto_route/test/url_path_separator_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('url path separator', () {
    // Steps: '/' is home; '/shelf' holds 'item/:id'. Open the app, then open
    // '/shelf/item/7'.
    // Should: the item page shows, the url is '/shelf/item/7' and the shelf
    // match's fullPath is '/shelf/item/7'.
    testWidgets('A nested link builds its url with "/"', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          NamedRouteDef(
            name: 'ShelfRoute',
            path: '/shelf',
            builder: (_, _) => const AutoRouter(),
            children: [
              NamedRouteDef(
                name: 'ItemRoute',
                path: 'item/:id',
                builder: (_, data) =>
                    Scaffold(body: Text('item ${data.params.getString('id')}')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await pumpRouterAppWithConfig(tester, router);
      expect(find.text('home'), findsOneWidget);

      // The navigation completes once its page is built, which takes frames
      // the test pumps.
      unawaited(router.navigatePath('/shelf/item/7'));
      await pumpUntilFound(tester, find.text('item 7'));
      expect(find.text('item 7'), findsOneWidget);
      expect(router.currentUrl, '/shelf/item/7');
      expect(
        router.matcher.match('/shelf/item/7')?.singleOrNull?.fullPath,
        '/shelf/item/7',
      );
      await expectBrowserUrl('/shelf/item/7');
    });
  });
}
