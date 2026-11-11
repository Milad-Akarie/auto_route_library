import 'dart:async';
import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// The args of a popped page are garbage collected.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/2322
// Headless test: auto_route/test/simple_router/popped_args_released_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('popped args released', () {
    // Steps: push DetailRoute with args, go back, then force a garbage
    // collection.
    // Should: nothing holds the args any more.
    testWidgets(
      'the args of a popped page are garbage collected',
      (tester) async {
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
              path: '/detail',
              page: PageInfo(
                'DetailRoute',
                builder: (data) =>
                    _TextPage('Detail ${data.argsAs<_DetailArgs>().counter}'),
              ),
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        late final WeakReference<_DetailArgs> args;
        // In a closure, so no local variable of this test holds the args.
        () {
          // Not const: a const instance is never garbage collected, which is
          // what this test checks. The counter is read at run time, so the
          // instance is made when the test runs.
          final counter = int.parse('42');
          final route = NamedRoute('DetailRoute', args: _DetailArgs(counter));
          args = WeakReference(route.args!);
          unawaited(router.push(route));
        }();
        await tester.pumpAndSettle();
        expect(find.text('Detail 42'), findsOneWidget);

        await systemBack(tester);
        expect(find.text('HomeRoute'), findsOneWidget);
        await tester.runAsync(_collectGarbage);
        expect(args.target, isNull);
      },
      // Web has no reachabilityBarrier to wait for a full collection on.
      skip: kIsWeb,
    );
  });
}

class _DetailArgs {
  const new(this.counter);

  final int counter;
}

/// Shows [text] on a plain page.
class _TextPage extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: Text(text)));
}

/// Allocates garbage until the VM has run two full collections.
///
/// The VM raises [reachabilityBarrier] after each full collection, which
/// clears weak references to objects nothing else holds.
Future<void> _collectGarbage() async {
  final barrier = reachabilityBarrier;
  final garbage = <List<DateTime>>[];
  while (reachabilityBarrier < barrier + 2) {
    garbage.add(List.generate(30000, DateTime.new));
    if (garbage.length > 100) garbage.removeAt(0);
    await Future<void>.delayed(.zero);
  }
}
