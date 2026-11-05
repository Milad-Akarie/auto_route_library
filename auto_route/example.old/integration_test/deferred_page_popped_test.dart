import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A deferred page popped before its library loads throws nothing once the
// library loads.
// Headless test: auto_route/test/deferred_page_popped_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('deferred page popped', () {
    // Steps: push DeferredRoute, whose page is a DeferredWidget still loading
    // its library, go back, then let the library finish loading.
    // Should: the late load changes nothing and throws nothing.
    testWidgets(
      'a deferred page popped before its library loads throws nothing',
      (tester) async {
        final library = Completer<void>();
        Future<void> loadLibrary() => library.future;
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo(
                'HomeRoute',
                builder: (_) => const _TextPage('HomeRoute'),
              ),
            ),
            AutoRoute(
              path: '/deferred',
              page: PageInfo(
                'DeferredRoute',
                builder: (_) => DeferredWidget(
                  loadLibrary,
                  () => const _TextPage('DeferredRoute'),
                ),
              ),
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        unawaited(router.pushPath('/deferred'));
        // Not pumpAndSettle: the loading placeholder spins until the library
        // loads.
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.byType(DeferredWidget), findsOneWidget);
        expect(find.text('DeferredRoute'), findsNothing);

        router.pop();
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('HomeRoute'), findsOneWidget);
        library.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('DeferredRoute'), findsNothing);
      },
    );
  });
}

/// Pumps frames for [duration], 100 milliseconds apart.
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  for (
    var elapsed = Duration.zero;
    elapsed < duration;
    elapsed += const Duration(milliseconds: 100)
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Shows [text] on a plain page.
class _TextPage extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: Text(text)));
}
