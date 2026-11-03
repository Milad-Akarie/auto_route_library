import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// On web, the address bar keeps encoded characters encoded, so a '#' in a
// param survives a refresh.
// https://github.com/Milad-Akarie/auto_route_library/issues/1812
// Headless test: auto_route/test/web/encoded_url_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  RootStackRouter buildRouter() => RootStackRouter.build(
    routes: [
      AutoRoute(page: FirstRoute.page, path: '/'),
      AutoRoute(page: _SecondsRoute.page, path: '/seconds/:id'),
    ],
  );

  // Steps: push a page whose path param and query param are '123#456#789',
  // then open the app again at the url it shows, as a refresh does.
  // Should: the url, and on web the address bar, holds '#' as '%23', and the
  // reopened page reads the whole '123#456#789', not '123'.
  testWidgets('A "#" in a path param survives a refresh', (tester) async {
    final router = buildRouter();
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(_SecondsRoute(id: '123#456#789', query: '123#456#789')));
    await tester.pumpAndSettle();
    expect(find.text('id 123#456#789, query 123#456#789'), findsOneWidget);
    const encoded = '/seconds/123%23456%23789?query=123%23456%23789';
    expect(router.urlState.uri.toString(), encoded);
    await expectBrowserUrl(encoded);

    await tester.pumpWidget(const SizedBox());
    await pumpRouterApp(tester, buildRouter(), initialLink: encoded);
    expect(find.text('id 123#456#789, query 123#456#789'), findsOneWidget);
  });
}

class _SecondsRoute extends PageRouteInfo<void> {
  _SecondsRoute({required String id, String? query})
    : super(name, rawPathParams: {'id': id}, rawQueryParams: {'query': query});

  static const String name = 'SecondsRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (data) => Text(
      'id ${data.inheritedPathParams.getString('id')}, query ${data.queryParams.optString('query')}',
    ),
  );
}
