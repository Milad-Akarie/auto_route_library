@TestOn('browser')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import '../simple_router/router.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();

  setUp(rewindBrowserHistory);

  // flutter/flutter#150312: with reevaluateListenable set, the listenable
  // fires as a page is popped, and the browser kept the popped page's url.
  // Push SecondRoute, push ThirdRoute, then in one callback fire the
  // listenable and pop, the listenable right away or a microtask later, as
  // the reporter's stream does. The browser should show SecondRoute's url,
  // on SecondRoute's entry.
  for (final later in [false, true]) {
    testWidgets(
      'Popping as the reevaluate listenable fires updates the url, fired '
      'later: $later',
      (tester) async {
        final auth = ValueNotifier(0);
        addTearDown(auth.dispose);
        final router = SimpleRouter();
        await pumpRouterConfigApp(
          tester,
          router.config(reevaluateListenable: auth),
        );
        await settleBrowser(tester);
        final start = browserSerialCount;
        unawaited(router.push(const SecondRoute()));
        await settleBrowser(tester);
        unawaited(router.push(const ThirdRoute()));
        await settleBrowser(tester);
        expect(browserPath, '/third-route');

        if (later) {
          scheduleMicrotask(() => auth.value++);
        } else {
          auth.value++;
        }
        router.pop();
        await settleBrowser(tester);
        expectCurrentPage(router, SecondRoute.name);
        expect(browserPath, '/second-route');
        expect(browserSerialCount, start + 1);

        await pressBrowserBack(tester);
        expectCurrentPage(router, FirstRoute.name);
        expect(browserSerialCount, start);
      },
    );
  }
}
