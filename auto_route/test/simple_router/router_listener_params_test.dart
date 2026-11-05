import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#108674: navigating between two locations of the same route
// that differ only in a path param did not notify the router's listeners.
// Steps: open /family/f1/person/p1, listen to the router, then navigate to
// /family/f1/person/p2.
// Should: the listener is told, the url and the page's param change.
void main() {
  testWidgets('A router listener hears navigation to the same route with another path param', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'HomeRoute', path: '/', initial: true, builder: (_, _) => const Text('home')),
        NamedRouteDef(
          name: 'PersonRoute',
          path: '/family/:fid/person/:pid',
          builder: (context, data) => Text('person ${data.params.getString('pid')}'),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.pushPath('/family/f1/person/p1'));
    await tester.pumpAndSettle();
    expect(find.text('person p1'), findsOneWidget);

    var notified = 0;
    void onChange() => notified++;
    router.addListener(onChange);
    addTearDown(() => router.removeListener(onChange));
    unawaited(router.navigatePath('/family/f1/person/p2'));
    await tester.pumpAndSettle();

    expect(notified, greaterThan(0));
    expect(router.currentUrl, '/family/f1/person/p2');
    expect(find.text('person p2'), findsOneWidget);
  });
}
