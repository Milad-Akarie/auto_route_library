import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/restorable_app.dart';

// Back after state restoration returns through the pages before the
// restored one, instead of closing the app.
// https://github.com/Milad-Akarie/auto_route_library/issues/2253
// Headless test: auto_route/test/restoration/restore_stack_test.dart
//
// WidgetTester.restartAndRestore ends the app's widget tree and starts it
// again from the data Flutter saved for restoration, which is what the
// platform hands back to an app it ended. A new router is built.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('restore history', () {
    // Flutter's state restoration doesn't run on the web, so the routers save
    // their pages only off the web.

    // The paths the generator gives these routes don't nest, so the restored
    // url alone can't bring the pages before ProductDetails back.
    RootStackRouter buildRouter() => .build(
      routes: [
        AutoRoute(
          page: namedPage('HomeRoute'),
          restorationId: (match) => match.name,
          initial: true,
        ),
        AutoRoute(
          page: namedPage('ProductsRoute'),
          restorationId: (match) => match.name,
        ),
        AutoRoute(
          page: namedPage('ProductDetailsRoute'),
          restorationId: (match) => match.name,
        ),
      ],
    );

    // Steps: go Home, Products, ProductDetails, restore the app, then go back
    // twice.
    // Should: ProductDetails shows, back shows Products, then Home, and only
    // then would Android close the app.
    testWidgets(
      'back after restoration returns through the pages before it',
      (tester) async {
        await pumpRestorableApp(tester, buildRouter);
        unawaited(
          RestorableRouterApp.router.push(const NamedRoute('ProductsRoute')),
        );
        await tester.pumpAndSettle();
        unawaited(
          RestorableRouterApp.router.push(
            const NamedRoute('ProductDetailsRoute'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.restartAndRestore();
        await tester.pumpAndSettle();
        expect(find.text('ProductDetailsRoute'), findsOneWidget);
        expect(RestorableRouterApp.router.stack.map((page) => page.name), [
          'HomeRoute',
          'ProductsRoute',
          'ProductDetailsRoute',
        ]);

        await systemBack(tester);
        expect(find.text('ProductsRoute'), findsOneWidget);
        await systemBack(tester);
        expect(find.text('HomeRoute'), findsOneWidget);
        expect(await doesAndroidSendBackToFlutter(), anyOf(isNull, isFalse));
      },
      skip: kIsWeb,
    );
  });
}
