import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/restorable_app.dart';

// Every page of the stacks comes back after state restoration.
// https://github.com/Milad-Akarie/auto_route_library/issues/2040
// Headless test: auto_route/test/restoration/restore_stack_test.dart
//
// WidgetTester.restartAndRestore ends the app's widget tree and starts it
// again from the data Flutter saved for restoration, which is what the
// platform hands back to an app it ended. A new router is built.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Flutter's state restoration doesn't run on the web, so the routers save
  // their pages only off the web.

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(path: '/', page: namedPage('SignUpRoute'), initial: true),
      AutoRoute(path: '/external', page: namedPage('ExternalRoute')),
      AutoRoute(path: '/settings', page: namedPage('SettingsRoute')),
      AutoRoute(
        path: '/shelf',
        page: const EmptyShellRoute('ShelfRoute'),
        children: [
          AutoRoute(path: '', page: namedPage('ShelfListRoute')),
          AutoRoute(path: 'item/:id', page: _itemPage),
        ],
      ),
    ],
  );

  // Steps: from the initial sign-up page, replace(ExternalRoute()), push
  // ExternalRoute twice, then restore the app and go back.
  // Should: all three ExternalRoute pages come back; back returns to the
  // second, then the first, and the sign-up page is gone.
  testWidgets(
    'a stack of the same page comes back after restoration',
    (tester) async {
      await pumpRestorableApp(tester, buildRouter);
      var router = RestorableRouterApp.router;
      unawaited(router.replace(const NamedRoute('ExternalRoute')));
      await tester.pumpAndSettle();
      unawaited(router.push(const NamedRoute('ExternalRoute')));
      await tester.pumpAndSettle();
      unawaited(router.push(const NamedRoute('ExternalRoute')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      router = RestorableRouterApp.router;
      expect(tester.takeException(), isNull);
      expect(router.stack.map((page) => page.name), [
        'ExternalRoute',
        'ExternalRoute',
        'ExternalRoute',
      ]);

      await systemBack(tester);
      expect(router.stack.map((page) => page.name), [
        'ExternalRoute',
        'ExternalRoute',
      ]);
      await systemBack(tester);
      expect(router.stack.map((page) => page.name), ['ExternalRoute']);
      expect(find.text('SignUpRoute'), findsNothing);
    },
    skip: kIsWeb,
  );

  // Steps: push the settings page, the shelf, and items 7 and 8 in the
  // shelf's nested router, then restore the app and go back four times.
  // Should: item 8 shows at '/shelf/item/8', then back shows item 7, the
  // shelf list, the settings page and the sign-up page.
  testWidgets(
    'every page of the stacks comes back after restoration',
    (tester) async {
      await pumpRestorableApp(tester, buildRouter);
      var router = RestorableRouterApp.router;
      unawaited(router.push(const NamedRoute('SettingsRoute')));
      await tester.pumpAndSettle();
      unawaited(router.pushPath('/shelf'));
      await tester.pumpAndSettle();
      unawaited(router.pushPath('item/7'));
      await tester.pumpAndSettle();
      unawaited(router.pushPath('item/8'));
      await tester.pumpAndSettle();
      expect(find.text('Item 8'), findsOneWidget);

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      router = RestorableRouterApp.router;
      expect(find.text('Item 8'), findsOneWidget);
      expect(router.currentPath, '/shelf/item/8');
      await expectBrowserUrl('/shelf/item/8');

      for (final expected in [
        'Item 7',
        'ShelfListRoute',
        'SettingsRoute',
        'SignUpRoute',
      ]) {
        await systemBack(tester);
        expect(find.text(expected), findsOneWidget);
      }
    },
    skip: kIsWeb,
  );
}

final _itemPage = PageInfo(
  'ItemRoute',
  builder: (data) => Scaffold(
    body: Center(
      child: Text('Item ${data.inheritedPathParams.getString('id')}'),
    ),
  ),
);
