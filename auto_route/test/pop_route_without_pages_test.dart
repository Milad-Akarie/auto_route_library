import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// flutter/flutter#187616: system back while the root router had no pages
// threw "Bad state: No element".
// Steps: call the delegate's popRoute, as Android back does, before the app
// is built, and after the root router's pages were all removed. It should
// answer false, so Android handles back, and not throw.
void main() {
  RootStackRouter buildRouter() => .build(
    routes: [AutoRoute(page: PageInfo('Home', builder: (_) => const Text('Home')), initial: true)],
  );

  testWidgets('popRoute before the first frame answers false', (tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    final delegate = router.delegate();

    expect(await delegate.popRoute(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('popRoute with every page removed answers false', (tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();

    router.removeWhere((_) => true);
    await tester.pump();

    expect(router.stack, isEmpty);
    expect(await router.delegate().popRoute(), isFalse);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
