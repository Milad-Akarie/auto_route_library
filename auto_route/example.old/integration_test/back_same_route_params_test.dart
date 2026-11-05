import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Going back walks back through one route pushed with different path params.
// flutter/flutter#186052
// Headless test: auto_route/test/web/encoded_url_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: push the item route three times, with path params holding ':',
  // '@', '+' and ' ', then go back three times: the browser's back button on
  // web, system back elsewhere.
  // Should: each step shows the item before, with its param whole, and the
  // last one the first page.
  testWidgets(
    'Going back walks back through one route pushed with different params (flutter/flutter#186052)',
    (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, path: '/'),
          AutoRoute(page: _ItemRoute.page, path: '/items/:id'),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);
      final start = browserEntryIndex();
      const ids = ['some:information:blabla', 'a@b', 'a+b c'];
      for (final id in ids) {
        unawaited(router.push(_ItemRoute(id)));
        await pumpUntilFound(tester, find.text('Item $id'));
      }
      await expectBrowserUrl('/items/a+b%20c');

      Future<void> goBack(int entry) async {
        if (kIsWeb) {
          pressBrowserBack();
          await expectBrowserEntry(entry);
          await tester.pumpAndSettle();
        } else {
          await systemBack(tester);
        }
      }

      for (final (i, id) in ids.reversed.skip(1).indexed) {
        await goBack((start ?? 0) + ids.length - 1 - i);
        expect(find.text('Item $id'), findsOneWidget);
        expect(router.stack, hasLength(ids.length - i));
      }
      await goBack(start ?? 0);
      expectCurrentPage(router, FirstRoute.name);
      expect(router.stack, hasLength(1));
      await expectBrowserUrl('/');
      expect(tester.takeException(), isNull);
    },
  );
}

class _ItemRoute extends PageRouteInfo<void> {
  _ItemRoute(String id) : super(name, rawPathParams: {'id': id});

  static const String name = 'ItemRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => Scaffold(
      body: SafeArea(
        child: Text('Item ${data.inheritedPathParams.getString('id')}'),
      ),
    ),
  );
}
