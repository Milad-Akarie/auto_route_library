import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../restoration/restoration_test_utils.dart';
import '../router_test_utils.dart';

// A query param pushed as a bool is read with optBool.
// https://github.com/Milad-Akarie/auto_route_library/pull/2222
// Steps: router.push(NamedRoute('FlagRoute', queryParams: {'f': true})), the
// page builder reads data.queryParams.optBool('f').
// Should: the page shows the flag, without NoSuchMethodError on toLowerCase.
void main() {
  final flagPage = PageInfo('FlagRoute', builder: (data) => Text('Flag ${data.queryParams.optBool('f') ?? 'null'}'));

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(path: '/', page: page('HomeRoute'), initial: true),
      AutoRoute(path: '/flag', page: flagPage),
    ],
  );

  testWidgets('a page pushed with a bool query param reads it with optBool', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('FlagRoute', queryParams: {'f': true})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Flag true'), findsOneWidget);
  });

  testWidgets('a page opened from a deep link reads the text value with optBool', (tester) async {
    final router = buildRouter();
    await pumpRouterApp(tester, router, initialLink: '/flag?f=false');
    expect(tester.takeException(), isNull);
    expect(find.text('Flag false'), findsOneWidget);
  });

  // The saved state keeps the bool as a bool, so the restored page reads it
  // through the same optBool.
  testWidgets('a restored page reads its saved bool query param', (tester) async {
    await tester.pumpWidget(RestorableRouterApp(buildRouter));
    await tester.pumpAndSettle();
    unawaited(RestorableRouterApp.router.push(const NamedRoute('FlagRoute', queryParams: {'f': true})));
    await tester.pumpAndSettle();
    expect(find.text('Flag true'), findsOneWidget);

    await tester.restartAndRestore();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Flag true'), findsOneWidget, reason: 'after tester.restartAndRestore()');
  }, skip: kIsWeb);
}
