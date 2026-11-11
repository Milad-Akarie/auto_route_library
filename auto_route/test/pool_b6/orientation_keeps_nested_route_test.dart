import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/771
// Setup, as in the report (auto_route 2.4.2, Android): a /map page whose
// nested AutoRouter sits in a bottom sheet (SizedBox) in portrait and in a
// side bar (Row) in landscape, with children 'location' (initial) and 'poi'.
// The router has no GlobalKey.
// Steps: open /map/poi, then turn the device from portrait to landscape.
// Reported: everything jumps back to the initial child, and
// innerRouterOf(MapRoute) is null.
// Should: the poi page stays, at the url /map/poi, and the map page still
// has its inner router.
void main() {
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'MapRoute',
          path: '/map',
          initial: true,
          builder: (context, _) => Scaffold(
            body: MediaQuery.orientationOf(context) == .portrait
                ? const Column(
                    children: [
                      Text('portrait'),
                      SizedBox(height: 300, child: AutoRouter()),
                    ],
                  )
                : const Row(
                    children: [
                      Text('landscape'),
                      SizedBox(width: 300, child: AutoRouter()),
                    ],
                  ),
          ),
          children: [
            NamedRouteDef(
              name: 'LocationRoute',
              path: 'location',
              initial: true,
              builder: (_, _) => const Text('Location'),
            ),
            NamedRouteDef(
              name: 'PoiRoute',
              path: 'poi',
              builder: (_, _) => const Text('Poi'),
            ),
          ],
        ),
      ],
    );
  });

  testWidgets('Turning the device keeps the nested page and its router', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text('portrait'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    unawaited(router.navigatePath('/map/poi'));
    await tester.pumpAndSettle();
    expect(find.text('Poi'), findsOneWidget);

    tester.view.physicalSize = const Size(900, 600);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('landscape'), findsOneWidget);
    expect(
      find.text('Poi'),
      findsOneWidget,
      reason: 'after tester.view.physicalSize = const Size(900, 600)',
    );
    expect(router.currentPath, '/map/poi');
    expect(router.innerRouterOf<StackRouter>('MapRoute'), isNotNull);
  });
}
