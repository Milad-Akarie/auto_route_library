import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Steps: an open app calls replaceAll with an empty list.
  // Should: nothing changes and nothing throws, since there is no route to
  // replace the stack with.
  testWidgets('replaceAll with no routes leaves the stack as it is', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Text('home'),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());

    await router.replaceAll(const []);
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['HomeRoute']);
  });
}
