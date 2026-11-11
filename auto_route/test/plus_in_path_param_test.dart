import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';

import 'centered_named_page.dart';
import 'router_test_utils.dart';

void main() {
  // https://github.com/flutter/flutter/issues/101757
  // A path param 'company+2' showed in the url as 'company%2B2'. In the url
  // the router reports, a '+' in the path is not escaped, and the page reads
  // the value back whole.
  testWidgets(
    "A '+' in a path param reaches the page and reads back from the url (flutter/flutter#101757)",
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/',
            builder: (_, _) => const CenteredNamedPage('HomeRoute'),
          ),
          NamedRouteDef(
            name: 'CompanyRoute',
            path: '/:company',
            builder: (_, data) => CenteredNamedPage(
              'company ${data.params.getString('company')}',
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      unawaited(
        router.navigate(
          const NamedRoute('CompanyRoute', params: {'company': 'company+2'}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('company company+2'), findsOneWidget);
      expect(router.urlState.url, '/company+2');
    },
  );

  testWidgets(
    "A '+' in the url of a deep link reaches the path param whole (flutter/flutter#101757)",
    (tester) async {
      final reopened = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'CompanyRoute',
            path: '/:company',
            builder: (_, data) => CenteredNamedPage(
              'company ${data.params.getString('company')}',
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, reopened, initialLink: '/company+2');
      expect(find.text('company company+2'), findsOneWidget);
    },
  );
}
