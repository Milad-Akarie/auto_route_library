import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#112444: the builder of a shell route read no path params of
// the page shown in it, where the page itself read them.
// Steps: a host page with a nested router with 'a' and 'b/:bParam'; the host
// shows context.topRoute next to its nested router; navigate to /b/42.
// Should: the host reads the params and the url of the shown page.
void main() {
  testWidgets('A shell page reads the path params of the page shown in it', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/',
          initial: true,
          builder: (context, _) {
            final top = context.topRoute;
            return Column(
              children: [
                Text('shell: ${top.name} ${top.params.rawMap} ${top.match}'),
                const Expanded(child: AutoRouter()),
              ],
            );
          },
          children: [
            NamedRouteDef(
              name: 'ARoute',
              path: 'a',
              initial: true,
              builder: (_, _) => const Text('a'),
            ),
            NamedRouteDef(
              name: 'BRoute',
              path: 'b/:bParam',
              builder: (_, data) =>
                  Text('b ${data.params.getString('bParam')}'),
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigatePath('/b/42'));
    await tester.pumpAndSettle();
    expect(find.text('b 42'), findsOneWidget);
    expect(find.textContaining('shell: BRoute {bParam: 42}'), findsOneWidget);
  });
}
