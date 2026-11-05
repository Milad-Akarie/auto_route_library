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

  late SimpleRouter router;
  setUp(() async {
    router = SimpleRouter();
    await rewindBrowserHistory();
  });

  // flutter/flutter#112765: the browser back button with a dialog open.
  // Open FirstRoute, push SecondRoute, show a dialog, press the browser's back
  // button. The dialog has no history entry, so the press goes to the entry of
  // FirstRoute: the dialog and SecondRoute both close, with no error.
  testWidgets('The browser back button with a dialog open goes to the page before', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;
    unawaited(router.push(const SecondRoute()));
    await settleBrowser(tester);
    showDialog<void>(context: router.navigatorKey.currentContext!, builder: (_) => const Text('Dialog'));
    await settleBrowser(tester);
    expect(find.text('Dialog'), findsOneWidget);

    await pressBrowserBack(tester);
    expect(find.text('Dialog'), findsNothing);
    expectCurrentPage(router, FirstRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name]);
    expect(browserPath, '/');
    expect(browserSerialCount, start);
    expect(tester.takeException(), isNull);
  });

  // flutter/flutter#132950: a package pushes its own pages with Navigator 1.0
  // on the router's navigator, then the user presses the browser's back and
  // forward buttons.
  // Push SecondRoute, push a MaterialPageRoute on the router's navigator,
  // press back: the pageless route and SecondRoute close. Press forward:
  // SecondRoute opens again, with no error.
  testWidgets('The browser buttons with a pageless route open keep the history whole', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;
    unawaited(router.push(const SecondRoute()));
    await settleBrowser(tester);
    router.navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('Package page')));
    await settleBrowser(tester);
    expect(find.text('Package page'), findsOneWidget);
    expect(browserSerialCount, start + 1);

    await pressBrowserBack(tester);
    expect(find.text('Package page'), findsNothing);
    expectCurrentPage(router, FirstRoute.name);
    expect(browserSerialCount, start);

    await pressBrowserForward(tester);
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name]);
    expect(browserPath, '/second-route');
    expect(browserSerialCount, start + 1, reason: 'after pressBrowserForward(tester)');
    expect(tester.takeException(), isNull);
  });

  // The same with the pageless route pushed on FirstRoute, the app's first
  // page: back goes to the entry before the app's, which the browser leaves
  // the app for, so only forward from there is left to test. Push SecondRoute,
  // go back to FirstRoute, push a pageless route, then press forward:
  // SecondRoute opens above FirstRoute and the pageless route closes.
  testWidgets('The browser forward button with a pageless route open goes to the page after', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;
    unawaited(router.push(const SecondRoute()));
    await settleBrowser(tester);
    await pressBrowserBack(tester);
    router.navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('Package page')));
    await settleBrowser(tester);

    await pressBrowserForward(tester);
    expect(find.text('Package page'), findsNothing);
    expectCurrentPage(router, SecondRoute.name);
    expect(router.stack.map((p) => p.name), [FirstRoute.name, SecondRoute.name]);
    expect(browserSerialCount, start + 1);
    expect(tester.takeException(), isNull);
  });
}
