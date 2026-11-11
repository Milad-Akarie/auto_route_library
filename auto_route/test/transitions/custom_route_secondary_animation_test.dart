import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/932
  // Reported: the secondaryAnimation a CustomRoute's transitionsBuilder gets
  // stayed at 0 while another page was pushed over it.
  // Steps: page A is a CustomRoute whose transitionsBuilder keeps its
  // secondaryAnimation; push B, a CustomRoute of 300ms, over it.
  // Should: A's secondaryAnimation runs from 0 to 1 while B comes in, and
  // back to 0 when B is popped.
  testWidgets(
    'A CustomRoute gets a running secondaryAnimation when a CustomRoute is '
    'pushed over it',
    (tester) async {
      Animation<double>? secondary;
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'ARoute',
            path: '/',
            type: RouteType.custom(
              transitionsBuilder: (_, _, secondaryAnimation, child) {
                secondary = secondaryAnimation;
                return child;
              },
            ),
            builder: (_, _) => const Scaffold(body: Text('ARoute')),
          ),
          NamedRouteDef(
            name: 'BRoute',
            path: '/b',
            type: RouteType.custom(
              transitionsBuilder: TransitionsBuilders.slideLeft,
              duration: const Duration(milliseconds: 300),
            ),
            builder: (_, _) => const Scaffold(body: Text('BRoute')),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      expect(secondary!.value, 0);

      unawaited(router.push(const NamedRoute('BRoute')));
      final values = <double>[];
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        values.add(secondary!.value);
      }
      // The animation starts in the frame after the push, then runs for 300ms.
      expect(values, [
        0,
        closeTo(1 / 6, 0.01),
        closeTo(2 / 6, 0.01),
        closeTo(3 / 6, 0.01),
        closeTo(4 / 6, 0.01),
      ]);
      await tester.pumpAndSettle();
      expect(secondary!.value, 1);

      router.pop();
      await tester.pumpAndSettle();
      expect(secondary!.value, 0, reason: 'after router.pop()');
    },
  );
}
