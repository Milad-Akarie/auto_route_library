import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// Going back returns to the same route pushed twice with equal arguments.
// Headless tests: auto_route/test/simple_router/back_same_url_test.dart
// (native) and auto_route/test/web/back_same_url_web_test.dart (web).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: SecondRoute.page, path: '/second'),
      ],
    );
  });

  Future<void> pushSecondTwice(WidgetTester tester) async {
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    unawaited(router.push(const SecondRoute()));
    await tester.pumpAndSettle();
    expect(router.stack.length, 3);
    await expectBrowserUrl('/second');
  }

  // Steps: push Second, push Second again, then call back().
  // Should: the first Second, not First.
  testWidgets('back() returns to the same route pushed with equal arguments', (tester) async {
    await pushSecondTwice(tester);
    final secondEntry = browserEntryIndex();

    router.back();
    if (kIsWeb) await expectBrowserEntry(secondEntry! - 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.current.name, SecondRoute.name);
    expect(router.stack.length, 2);
    await expectBrowserUrl('/second');
  });

  // Steps: the same, going back with the browser's back button.
  // Should: the first Second, not First.
  // Web only: elsewhere, system back pops the page, which already worked.
  testWidgets('The browser back button returns to the same route pushed with equal arguments', (tester) async {
    await pushSecondTwice(tester);
    final secondEntry = browserEntryIndex()!;

    pressBrowserBack();
    await expectBrowserEntry(secondEntry - 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(router.current.name, SecondRoute.name);
    expect(router.stack.length, 2);
    await expectBrowserUrl('/second');
  }, skip: !kIsWeb);
}
