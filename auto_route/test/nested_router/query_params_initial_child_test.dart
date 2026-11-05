import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1089
  // Reported: the query params of a url reached the parent
  // route, 'comments/:objectId', but not its initial child.
  // Steps: CommentsRoutedRoute 'comments/:objectId' hosts a router whose
  // initial child is CommentsRoute; navigatePath('/comments/5?objectType=spot').
  // Should: CommentsRoute gets objectType 'spot' and the path param 5.
  testWidgets('The initial child of a route gets the query params of the url', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'CommentsRoutedRoute',
          path: '/comments/:objectId',
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'CommentsRoute',
              path: '',
              builder: (_, data) => Scaffold(
                body: Text(
                  'type ${data.queryParams.optString('objectType') ?? 'null'} '
                  'id ${data.inheritedPathParams.optInt('objectId') ?? 'null'}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    unawaited(router.navigatePath('/comments/5?objectType=spot'));
    await tester.pumpAndSettle();

    expect(find.text('type spot id 5'), findsOneWidget);
  });
}
