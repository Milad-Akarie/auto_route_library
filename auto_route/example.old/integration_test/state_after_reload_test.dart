import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// On web, an app started again on a browser entry it saved a state in reads
// that state. flutter/flutter#108697
// Headless test: auto_route/test/web/state_after_reload_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('state after reload', () {
    // Steps: make the browser's entry hold '/p2' with the state the engine
    // keeps for the app, as when the user comes back from another site, then
    // start the app there.
    // Should: router.pathState is the saved state. (The engine keeps counting
    // entries across the tests of one launch, so whether the app writes a new
    // entry is checked by the headless test, which starts with a fresh
    // history.)
    testWidgets(
      'an app started on a browser entry it saved a state in reads that state',
      skip: !kIsWeb,
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo('P1', builder: (_) => const Text('P1')),
            ),
            AutoRoute(
              path: '/p2',
              page: PageInfo('P2', builder: (_) => const Text('P2')),
            ),
          ],
        );
        addTearDown(router.dispose);
        final dispatcher = tester.binding.platformDispatcher;
        addTearDown(dispatcher.clearDefaultRouteNameTestValue);
        dispatcher.defaultRouteNameTestValue = '/p2';
        saveBrowserEntryState('/p2', 'saved');

        tester.binding.attachRootWidget(
          tester.binding.wrapWithDefaultView(
            MaterialApp.router(routerConfig: router.config()),
          ),
        );
        tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);
        await tester.pumpAndSettle();

        expect(router.stack.map((page) => page.name), ['P2']);
        expect(router.pathState, 'saved');
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
