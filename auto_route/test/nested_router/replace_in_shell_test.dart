import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#137545: replacing a page inside a shell route, a host page
// whose nested router shows its children, threw "Null check operator used on
// a null value".
// The reporter's app: a host at '/' wraps its nested router; its children are
// 'one' (initial) and 'two'. On OneRoute, tap the button that calls
// context.router.replace(TwoRoute): TwoRoute replaces OneRoute in the nested
// router, with no error, and the url is '/two'. Then pop: nothing is left to
// pop in the nested router, so the app stays on TwoRoute.
void main() {
  testWidgets('Replacing a page inside a shell route shows the new page', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/',
          builder: (_, _) => const Center(child: AutoRouter()),
          children: [
            NamedRouteDef(
              name: 'OneRoute',
              path: 'one',
              initial: true,
              builder: (context, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.router.replace(const NamedRoute('TwoRoute')),
                  child: const Text('navigate'),
                ),
              ),
            ),
            NamedRouteDef(
              name: 'TwoRoute',
              path: 'two',
              builder: (_, _) => const Scaffold(body: Text('TwoRoute')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(router.currentUrl, '/one');

    await tester.tap(find.text('navigate'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final shellRouter = router.innerRouterOf<StackRouter>('ShellRoute')!;
    expect(shellRouter.stack.map((p) => p.name), ['TwoRoute']);
    expect(find.text('TwoRoute'), findsOneWidget);
    expect(router.currentUrl, '/two');

    expect(await router.maybePop(), isFalse);
    await tester.pumpAndSettle();
    expect(
      find.text('TwoRoute'),
      findsOneWidget,
      reason: 'after final shellRouter = router.innerRouterOf<StackRouter>(Sh',
    );
    expect(tester.takeException(), isNull, reason: 'after final shellRouter = router.innerRouterOf<StackRouter>(Sh');
  });
}
