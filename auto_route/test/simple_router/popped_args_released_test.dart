import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _DetailArgs {
  const _DetailArgs(this.counter);

  final int counter;
}

PageInfo _detailPage = PageInfo('DetailRoute', builder: (data) => Text('Detail ${data.argsAs<_DetailArgs>().counter}'));

/// Allocates garbage until the VM has run two full collections.
///
/// The VM raises [reachabilityBarrier] after each full collection, which
/// clears weak references to objects nothing else holds.
Future<void> _collectGarbage() async {
  final barrier = reachabilityBarrier;
  final garbage = <List<DateTime>>[];
  while (reachabilityBarrier < barrier + 2) {
    garbage.add(List.generate(30000, (n) => DateTime(n)));
    if (garbage.length > 100) garbage.removeAt(0);
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2322
  // Steps: push DetailRoute with args, pop it, then force a garbage collection.
  // Happened: the args stayed in memory, held by the router's navigation
  // history, one more instance on each push and pop.
  // Should: nothing holds the args once the page is popped.
  testWidgets(
    'The args of a popped page are garbage collected',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
          ),
          AutoRoute(path: '/detail', page: _detailPage),
        ],
      );
      await pumpRouterApp(tester, router);
      late final WeakReference<_DetailArgs> args;
      // In a closure, so no local variable of this test holds the args.
      () {
        // Not const: a const instance is never garbage collected, which is
        // what this test checks.
        // ignore: prefer_const_constructors
        final route = NamedRoute<_DetailArgs>('DetailRoute', args: _DetailArgs(42));
        args = WeakReference(route.args!);
        router.push(route);
      }();
      await tester.pumpAndSettle();
      expect(find.text('Detail 42'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      await tester.runAsync(_collectGarbage);
      expect(args.target, isNull);
    },
    // Web has no reachabilityBarrier to wait for a full collection on.
    skip: kIsWeb,
  );
}
