import 'dart:async';

import 'package:example/deferred/deferred.router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';

// A deferred page and a page that doesn't ask for it, declared in one file,
// give a router that compiles and opens both.
// Generator test: auto_route_generator/test/deferred_loading_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app on the deferred first page of
  // lib/deferred/pages.dart, then push the second page of that
  // file. Should: each page loads and shows; the app compiled at all.
  testWidgets('a deferred page and an eager page from one file both open', (
    tester,
  ) async {
    final router = DeferredRouter();
    await pumpRouterApp(tester, router);
    await pumpUntilFound(tester, find.text('First page'));
    expect(find.text('First page'), findsOneWidget);

    unawaited(router.pushPath('/second'));
    await pumpUntilFound(tester, find.text('Second page'));
    expect(find.text('Second page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
