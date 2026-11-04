import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

Widget _page(String name) => Scaffold(body: Center(child: Text(name)));

void main() {
  // https://github.com/flutter/flutter/issues/99122
  // A redirect sent the app to '/invoice?url=a', and going back to '/' still
  // showed the query params of '/invoice'. Steps: open '/', push '/old' (a
  // redirect to '/invoice?url=a'), pop. The url and the current route's query
  // params are those of '/', which has none.
  testWidgets('Popping a page opened through a redirect drops its query params (flutter/flutter#99122)', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'HomeRoute', path: '/', builder: (_, _) => _page('HomeRoute')),
        RedirectRoute(path: '/old', redirectTo: '/invoice?url=a'),
        NamedRouteDef(name: 'InvoiceRoute', path: '/invoice', builder: (_, _) => _page('InvoiceRoute')),
      ],
    );
    await pumpRouterApp(tester, router);

    unawaited(router.pushPath('/old'));
    await tester.pumpAndSettle();
    expect(router.urlState.url, '/invoice?url=a');
    expect(router.current.queryParams.rawMap, {'url': 'a'});

    router.pop();
    await tester.pumpAndSettle();
    expectCurrentPage(router, 'HomeRoute');
    expect(router.urlState.url, '/');
    expect(router.current.queryParams.rawMap, isEmpty);
  });
}
