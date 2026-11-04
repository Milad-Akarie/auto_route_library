import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // Steps: push DeferredRoute, whose page is a DeferredWidget still loading
  // its library, pop it, then let the library finish loading.
  // Happened: the loaded library called setState on the popped page's
  // disposed state, which threw "setState() called after dispose()".
  // Should: the late load changes nothing and throws nothing.
  testWidgets('A deferred page popped before its library loads throws nothing', (tester) async {
    final library = Completer<void>();
    Future<void> loadLibrary() => library.future;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
        ),
        AutoRoute(
          path: '/deferred',
          page: PageInfo(
            'DeferredRoute',
            builder: (_) => DeferredWidget(loadLibrary, () => const Text('DeferredRoute')),
          ),
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    unawaited(router.pushPath('/deferred'));
    // Not pumpAndSettle: the loading placeholder spins until the library
    // loads.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(DeferredWidget), findsOneWidget);
    expect(find.text('DeferredRoute'), findsNothing);

    router.pop();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('HomeRoute'), findsOneWidget);
    library.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('DeferredRoute'), findsNothing);
  });
}
