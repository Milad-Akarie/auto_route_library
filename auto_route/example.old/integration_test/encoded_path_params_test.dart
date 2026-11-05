import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A path param holding a reserved character is encoded in the url and reads
// back whole.
// https://github.com/Milad-Akarie/auto_route_library/issues/2070
// Headless test: auto_route/test/encoded_path_params_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  RootStackRouter buildRouter() => .build(
    routes: [
      AutoRoute(page: FirstRoute.page, path: '/'),
      AutoRoute(page: _FileRoute.page, path: '/files/:name'),
    ],
  );

  // Steps: push a page whose path param is 'reports/2024', then open the app
  // again at the url it shows.
  // Should: the url, and on web the address bar, is
  // '/files/reports%2F2024', and the reopened page reads 'reports/2024'.
  testWidgets(
    'A "/" in a path param is encoded in the url and reads back whole',
    (tester) async {
      final router = buildRouter();
      await pumpRouterAppWithConfig(tester, router);
      unawaited(router.push(_FileRoute(name: 'reports/2024')));
      await tester.pumpAndSettle();
      expect(find.text('File reports/2024'), findsOneWidget);
      const encoded = '/files/reports%2F2024';
      expect(router.urlState.uri.toString(), encoded);
      await expectBrowserUrl(encoded);

      await tester.pumpWidget(const SizedBox());
      await pumpRouterApp(tester, buildRouter(), initialLink: encoded);
      expect(tester.takeException(), isNull);
      expect(find.text('File reports/2024'), findsOneWidget);
    },
  );
}

class _FileRoute extends PageRouteInfo<void> {
  new({required String name}) : super(pageName, rawPathParams: {'name': name});

  static const String pageName = 'FileRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) =>
        Text('File ${data.inheritedPathParams.getString('name')}'),
  );
}
