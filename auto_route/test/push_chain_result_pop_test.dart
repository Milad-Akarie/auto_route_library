import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/429
// Setup, as in the report: page A pushes page B and awaits its result; B
// pushes page C and, when C's result arrives, pops itself with
// context.router.pop(); C pops itself when it is done.
// Steps: open A, push B, push C, let C pop.
// Happened: B got C's result and ran its pop, but B stayed on screen and A
// never got its result.
// Should: B is gone, A shows, and A's awaited push completes with B's result.
void main() {
  testWidgets('B pops itself after C popped and A gets the result', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _page('A'), path: '/', initial: true),
        AutoRoute(page: _chainPage('B'), path: '/b'),
        AutoRoute(page: _page('C'), path: '/c'),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    Object? resultOfB;
    var bCompleted = false;
    unawaited(
      router.push<String>(const NamedRoute('B')).then((result) {
        resultOfB = result;
        bCompleted = true;
      }),
    );
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'B');

    await tester.tap(find.text('open C'));
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'C');

    router.pop('from C');
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    expect(router.stack.map((page) => page.routeData.name), ['A']);
    expect(bCompleted, isTrue);
    expect(resultOfB, 'from B');
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));

PageInfo _chainPage(String name) => .new(
  name,
  builder: (_) => Scaffold(
    body: Builder(
      builder: (context) => Column(
        children: [
          Text(name),
          TextButton(
            onPressed: () => unawaited(_openC(context)),
            child: const Text('open C'),
          ),
        ],
      ),
    ),
  ),
);

/// What page B does: open C, and when C is done, pop B with a result.
Future<void> _openC(BuildContext context) async {
  final result = await context.router.push<String>(const NamedRoute('C'));
  if (result == 'from C' || result == null) {
    context.router.pop('from B');
  }
}
