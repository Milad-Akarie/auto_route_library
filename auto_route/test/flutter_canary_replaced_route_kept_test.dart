import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:material_ui/material_ui.dart';

import 'no_op.dart';

// Canary for Flutter bug https://github.com/flutter/flutter/issues/164934.
// Setup, without auto_route: a Navigator built from a pages list, as
// auto_route's routers build theirs.
// Steps: replace the top page with a new one 10 times, as auto_route's
// replace() does, then force garbage collections.
// Today Flutter keeps the most recently replaced route reachable after its
// page is gone, with the route's settings. In auto_route the settings are the
// AutoRoutePage, so its RouteData stays too. The page's State is released and
// only one replaced route is kept at a time, so memory does not grow. An app
// that replaces its splash page with its home page keeps the splash route
// until the next replace over the same page.
// If this test fails after a Flutter upgrade, Flutter now releases a replaced
// route: add a check to auto_route/test/leaks/released_objects_test.dart that
// a replaced page releases its RouteData, and drop this canary.
void main() {
  testWidgets('a page replaced in Navigator.pages releases its State, but its route stays reachable', (tester) async {
    final routes = <WeakReference<Route<Object?>>>[];
    final states = <WeakReference<State>>[];
    var pages = <Page<void>>[
      const MaterialPage(key: ValueKey('home'), child: Text('home')),
      MaterialPage(key: const ValueKey('page 0'), child: _TrackedPage(states)),
    ];
    late StateSetter setPages;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setPages = setState;
            return Navigator(observers: [_PushObserver(routes)], pages: pages, onDidRemovePage: ignoreArgument);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 1; i <= 10; i++) {
      setPages(() => pages = [...pages.take(1), MaterialPage(key: ValueKey('page $i'), child: _TrackedPage(states))]);
      await tester.pumpAndSettle();
    }
    expect(routes, hasLength(12));
    final replacedRoutes = routes.sublist(1, 11);
    final replacedStates = states.sublist(0, 10);
    for (var round = 0; round < 10 && replacedStates.any((state) => state.target != null); round++) {
      await tester.runAsync(() => forceGC(fullGcCycles: 2));
    }
    await tester.runAsync(() => forceGC(fullGcCycles: 2));

    expect(replacedStates.where((state) => state.target != null), isEmpty);
    expect(
      [
        for (final (index, route) in replacedRoutes.indexed)
          if (route.target != null) index,
      ],
      [9],
      reason: 'only the most recently replaced route is kept',
    );
  }, skip: kIsWeb); // Web has no reachabilityBarrier to wait for a full collection on.
}

class _TrackedPage extends StatefulWidget {
  const _TrackedPage(this.states);

  final List<WeakReference<State>> states;

  @override
  State<_TrackedPage> createState() => _TrackedPageState();
}

class _TrackedPageState extends State<_TrackedPage> {
  @override
  void initState() {
    super.initState();
    widget.states.add(WeakReference(this));
  }

  @override
  Widget build(BuildContext context) => const Text('page');
}

class _PushObserver extends NavigatorObserver {
  _PushObserver(this.routes);

  final List<WeakReference<Route<Object?>>> routes;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) => routes.add(WeakReference(route));
}
