import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

/// How many times each page's widget has built, by page name.
typedef BuildCounts = Map<String, int>;

/// A page named [name] that shows [body], or its name, and adds one to
/// [builds] each time its widget builds.
PageInfo countedPage(String name, BuildCounts builds, {Widget? body}) => .new(
  name,
  builder: (_) => Builder(
    builder: (_) {
      builds[name] = (builds[name] ?? 0) + 1;
      return Scaffold(body: body ?? Text(name));
    },
  ),
);

/// Opens [router] at the deep link [link], as the platform hands it to an app
/// that starts there, and waits for its pages to settle.
Future<void> pumpAtDeepLink(
  WidgetTester tester,
  RootStackRouter router,
  String link, {
  required bool shouldIncludePrefixMatches,
}) {
  final dispatcher = tester.binding.platformDispatcher;
  addTearDown(dispatcher.clearDefaultRouteNameTestValue);
  dispatcher.defaultRouteNameTestValue = link;
  return pumpRouterConfigApp(
    tester,
    router.config(includePrefixMatches: shouldIncludePrefixMatches),
  );
}
