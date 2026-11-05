import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/restorable_app.dart';

// A query param pushed as a bool is read with optBool.
// https://github.com/Milad-Akarie/auto_route_library/pull/2222
// Headless tests: auto_route/test/bool_query_param/bool_query_param_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final flagPage = PageInfo(
    'FlagRoute',
    builder: (data) => Scaffold(body: Center(child: Text('Flag ${data.queryParams.optBool('f')}'))),
  );

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(path: '/', page: namedPage('HomeRoute'), initial: true),
      AutoRoute(path: '/flag', page: flagPage),
    ],
  );

  // Steps: push NamedRoute('FlagRoute', queryParams: {'f': true}); the page
  // builder reads data.queryParams.optBool('f').
  // Should: the page shows the flag, without NoSuchMethodError on
  // toLowerCase, and the url carries f=true.
  testWidgets('a page pushed with a bool query param reads it with optBool', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('FlagRoute', queryParams: {'f': true})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Flag true'), findsOneWidget);
    expect(router.urlState.url, '/flag?f=true');
    await expectBrowserUrl('/flag?f=true');
  });

  // Steps: open the deep link /flag?f=false.
  // Should: the page shows the flag false.
  testWidgets('a deep link reads the text value with optBool', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router, initialLink: '/flag?f=false');
    expect(tester.takeException(), isNull);
    expect(find.text('Flag false'), findsOneWidget);
  });

  // Steps: push the page with f: true, then restore the app.
  // Should: the restored page shows the flag true.
  testWidgets('a restored page reads its saved bool query param', (tester) async {
    await pumpRestorableApp(tester, buildRouter);
    unawaited(RestorableRouterApp.router.push(const NamedRoute('FlagRoute', queryParams: {'f': true})));
    await tester.pumpAndSettle();
    expect(find.text('Flag true'), findsOneWidget);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Flag true'), findsOneWidget);
  }, skip: kIsWeb);
}
