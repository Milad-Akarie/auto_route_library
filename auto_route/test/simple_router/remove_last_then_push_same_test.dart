import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../init_count_page.dart';
import '../router_test_utils.dart';

// #1204: removing the only page and pushing the same route again showed the
// old page instead of building a new one, so the provider it created was not
// created again.
// Steps: the stack holds only HomeRoute, whose page counts its initState
// calls; a dialog over it calls popUntilRoot, removeLast and push(HomeRoute)
// in one callback.
// Should: the dialog is gone, the stack holds one HomeRoute, and its page
// was built anew, so initState ran a second time.
void main() {
  testWidgets('removeLast then push of the same route builds a new page', (
    tester,
  ) async {
    var homeInits = 0;
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          initial: true,
          builder: (_, _) => InitCountPage(() => homeInits++),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(homeInits, 1);

    final home = tester.element(find.text('Home'));
    showDialog<void>(
      context: home,
      builder: (dialog) => TextButton(
        onPressed: () {
          dialog.router.popUntilRoot();
          dialog.router.removeLast();
          unawaited(dialog.router.push(const NamedRoute('HomeRoute')));
        },
        child: const Text('OK'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('OK'), findsNothing);
    expect(router.stack.map((page) => page.name), ['HomeRoute']);
    expect(find.text('Home'), findsOneWidget);
    expect(homeInits, 2);
  });
}
