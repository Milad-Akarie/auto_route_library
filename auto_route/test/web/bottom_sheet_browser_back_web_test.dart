@TestOn('browser')
library;

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'browser_history.dart';

void main() {
  useRealBrowserHistory();
  setUp(rewindBrowserHistory);

  // https://github.com/Milad-Akarie/auto_route_library/issues/1600
  // Reported on web: the back button with a showModalBottomSheet open popped
  // the page under the sheet too, where the reporter expected only the sheet
  // to close.
  // Decided, as for a dialog (flutter/flutter#112765, guarded in
  // pageless_browser_back_web_test.dart): the sheet has no browser entry, so
  // the back button goes to the entry before, as a link to that url does.
  // Steps: push BRoute over ARoute, show a modal bottom sheet, press the
  // browser's back button.
  // Should: the sheet and BRoute close, ARoute shows at '/', with no error.
  testWidgets('The browser back button with a bottom sheet open goes to the page before', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ARoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('ARoute')),
        ),
        NamedRouteDef(
          name: 'BRoute',
          path: '/b',
          builder: (_, _) => const Scaffold(body: Text('BRoute')),
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    await settleBrowser(tester);
    final start = browserSerialCount;
    unawaited(router.push(const NamedRoute('BRoute')));
    await settleBrowser(tester);
    showModalBottomSheet<void>(context: tester.element(find.text('BRoute')), builder: (_) => const Text('Sheet'));
    await settleBrowser(tester);
    expect(find.text('Sheet'), findsOneWidget);

    await pressBrowserBack(tester);
    expect(find.text('Sheet'), findsNothing);
    expect(router.stack.map((p) => p.name), ['ARoute']);
    expect(find.text('ARoute'), findsOneWidget);
    expect(browserPath, '/');
    expect(browserSerialCount, start);
    expect(tester.takeException(), isNull);
  });
}
