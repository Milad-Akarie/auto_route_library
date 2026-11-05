import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/page_kinds_router.dart';

// Every page's semantics carry its route name as their identifier.
// https://github.com/Milad-Akarie/auto_route_library/issues/2115
// Headless test: auto_route/test/page_semantics_identifier_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the home page, then push a page of each route type in turn.
  // Should: the semantics tree holds a node whose identifier is the route
  // name of the page shown, as UI testing tools such as Appium read it.
  testWidgets('Each kind of page is found by its route name in the semantics tree', (tester) async {
    final handle = tester.ensureSemantics();
    final router = pageKindsRouter();
    await pumpRouterApp(tester, router);

    for (final name in pageKindNames) {
      if (name != 'HomeRoute') {
        unawaited(router.push(NamedRoute(name)));
        await tester.pumpAndSettle();
      }
      expect(find.bySemanticsIdentifier(name), findsOneWidget, reason: name);
      expect(find.semantics.byPredicate((node) => node.identifier == name), findsOne, reason: name);
    }
    handle.dispose();
  });
}
