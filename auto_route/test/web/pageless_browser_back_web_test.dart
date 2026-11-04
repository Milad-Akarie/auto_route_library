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
}
