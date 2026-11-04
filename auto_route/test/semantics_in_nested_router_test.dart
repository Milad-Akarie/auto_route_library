import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1535
  // Reported: test tools that find widgets through semantics, such as
  // Appium, could not reach or tap a Semantics-wrapped button on a page in a
  // nested router or tabs router.
  // Steps: a page inside a tab of an AutoTabsRouter, in a nested router,
  // holds Semantics(identifier: 'login_button') around a button; find it in
  // the semantics tree and tap the button through semantics.
  // Should: as in a MaterialApp without auto_route, the identifier is in the
  // tree and the tap reaches the button.
  for (final withRouter in [false, true]) {
    testWidgets('A button on a nested page is found and tapped through semantics '
        '(${withRouter ? 'nested in auto_route' : 'plain MaterialApp'})', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      Widget page() => Scaffold(
        body: Semantics(
          identifier: 'login_button',
          button: true,
          child: ElevatedButton(onPressed: () => taps++, child: const Text('Login')),
        ),
      );
      if (withRouter) {
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'HostRoute',
              path: '/',
              builder: (_, _) => AutoTabsRouter(routes: const [NamedRoute('TabRoute')], builder: (_, child) => child),
              children: [
                NamedRouteDef.shell(
                  name: 'TabRoute',
                  path: 'tab',
                  children: [NamedRouteDef(name: 'LoginRoute', path: '', builder: (_, _) => page())],
                ),
              ],
            ),
          ],
        );
        await pumpRouterConfigApp(tester, router.config());
      } else {
        await tester.pumpWidget(MaterialApp(home: page()));
      }

      expect(find.semantics.byPredicate((node) => node.identifier == 'login_button'), findsOne);
      tester.semantics.tap(find.semantics.byLabel('Login'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      handle.dispose();
    });
  }
}
