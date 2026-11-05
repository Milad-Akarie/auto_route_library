import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// popUntil on a nested router never shows the pages in between.
// flutter/flutter#59990
// Headless test: auto_route/test/nested_router/pop_until_hides_middle_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: a host page whose nested router has [A, B, C]; call popUntil for
  // A on the nested router and look at every frame of the pop.
  // Should: C animates out over A, B never shows, and B's push completes.
  testWidgets('popUntil on a nested router never shows the pages in between', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo(
            'HostRoute',
            builder: (_) => const Scaffold(body: SafeArea(child: AutoRouter())),
          ),
          children: [
            for (final name in ['A', 'B', 'C'])
              AutoRoute(
                path: name == 'A' ? '' : name.toLowerCase(),
                page: PageInfo(
                  name,
                  builder: (_) => ColoredBox(
                    color: Colors.white,
                    child: Center(child: Text(name)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final nested = router.innerRouterOf<StackRouter>('HostRoute')!;
    var wasBClosed = false;
    unawaited(nested.pushPath('b').then((_) => wasBClosed = true));
    await tester.pumpAndSettle();
    unawaited(nested.pushPath('c'));
    await tester.pumpAndSettle();

    nested.popUntil((route) => route.settings.name == 'A');
    final shown = <String>{};
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      for (final name in ['A', 'B', 'C']) {
        if (find.text(name).evaluate().isNotEmpty) shown.add(name);
      }
    }
    await tester.pumpAndSettle();

    expect(shown, {'A', 'C'});
    expect(wasBClosed, isTrue);
    expect(nested.stack.map((page) => page.name), ['A']);
    expect(find.text('A'), findsOneWidget);
  });
}
