import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'slider_wrap_page.dart';

// flutter/flutter#182287: switching the pages of a nested Navigator that
// hold sliders, many times over, made each frame slower, on one car display.
// Whether that is Flutter's or the Android embedder's is open there; this
// checks auto_route keeps nothing alive.
// Steps: a host page holds a nested router whose two pages, with no
// transition and maintainState: false, each show ten sliders in Heroes, as
// in the report; replace one page with the other 40 times, then with
// popAndPush 40 more, and force a garbage collection.
// Should: only the page on screen is left: no ticker keeps running, the
// nested router holds one page, and no replaced page's state stays in
// memory.
void main() {
  testWidgets(
    'replacing nested pages with sliders many times keeps no replaced page',
    (tester) async {
      final states = <WeakReference<State>>[];
      final values = List.generate(10, (_) => ValueNotifier(0.5));
      for (final value in values) {
        addTearDown(value.dispose);
      }
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HostRoute',
            path: '/',
            initial: true,
            builder: (_, _) => const Scaffold(
              body: Padding(padding: .all(50), child: AutoRouter()),
            ),
            children: [
              for (final name in ['Widget1', 'Widget2'])
                NamedRouteDef(
                  name: name,
                  path: name.toLowerCase(),
                  initial: name == 'Widget1',
                  maintainState: false,
                  type: .custom(
                    duration: const Duration(milliseconds: 400),
                    reverseDuration: const Duration(milliseconds: 400),
                    transitionsBuilder: TransitionsBuilders.noTransition,
                  ),
                  builder: (_, _) => SliderWrapPage(values, states),
                ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      final nested = router.innerRouterOf<StackRouter>('HostRoute')!;

      var current = 'Widget1';
      for (var i = 0; i < 80; i++) {
        current = current == 'Widget1' ? 'Widget2' : 'Widget1';
        final next = NamedRoute<Object?>(current);
        if (i < 40) {
          unawaited(nested.replace(next));
        } else {
          unawaited(nested.popAndPush(next));
        }
        await tester.pump(const Duration(milliseconds: 600));
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      expect(nested.stack.map((p) => p.name), [current]);
      expect(find.byType(Slider), findsNWidgets(10));
      expect(states, hasLength(81));

      final replaced = states.sublist(0, states.length - 1);
      for (var round = 0; round < 10; round++) {
        if (replaced.every((state) => state.target == null)) break;
        await tester.runAsync(() => forceGC(fullGcCycles: 2));
      }
      expect(replaced.where((state) => state.target != null), isEmpty);
    },
    // Web has no reachabilityBarrier to wait for a full collection on.
    skip: kIsWeb,
  );
}
