import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// On web, with Flutter's own route information provider, a deep link whose
// path param holds an encoded '#' keeps one browser history entry.
// Found with https://github.com/Milad-Akarie/auto_route_library/issues/1812
// Headless test: auto_route/test/web/encoded_url_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app, built from routerDelegate and
  // routeInformationParser, at '/seconds/1%232'.
  // Should: the page reads the whole '1#2', and on web the address bar holds
  // the link in the same history entry, not a second one.
  testWidgets('A deep link to an encoded url adds no history entry', (
    tester,
  ) async {
    const link = '/seconds/1%232';
    final entryBefore = browserEntryIndex() ?? 0;
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _secondsPage, path: '/seconds/:id'),
      ],
    );

    await pumpAppAtDeepLink(
      tester,
      link,
      MaterialApp.router(
        routeInformationParser: router.defaultRouteParser(),
        routerDelegate: router.delegate(),
      ),
    );
    expect(find.text('id 1#2'), findsOneWidget);
    await expectBrowserUrl(link);
    await expectAppWroteDeepLinkEntry(entryBefore);
  });
}

final _secondsPage = PageInfo(
  'SecondsRoute',
  builder: (data) => Text('id ${data.inheritedPathParams.getString('id')}'),
);
