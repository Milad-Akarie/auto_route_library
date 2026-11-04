import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/1544
  // Reported: navigating to '/home_screen/drug_database_screen/
  // add_drug_template_screen', three levels deep, showed the page and then
  // popped it after a few seconds.
  // Steps: AuthWrapperRoute '/home_screen' is a router; its child
  // DrugDatabaseRoute hosts a router of AddDrugTemplateRoute and
  // AddCriTemplateRoute. navigatePath to the deepest page, wait 3 seconds;
  // then pushPath to its sibling and wait again.
  // Should: each page stays, with its full path in the url.
  testWidgets('A page three levels deep stays open with its full path', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(name: 'SplashRoute', path: '/', builder: (_, _) => _page('SplashRoute')),
        NamedRouteDef.shell(
          name: 'AuthWrapperRoute',
          path: '/home_screen',
          children: [
            NamedRouteDef(name: 'HomeRoute', path: '', builder: (_, _) => _page('HomeRoute')),
            NamedRouteDef(
              name: 'DrugDatabaseRoute',
              path: 'drug_database_screen',
              builder: (_, _) => const Scaffold(
                body: Column(
                  children: [
                    Text('DrugDatabaseRoute'),
                    Expanded(child: AutoRouter()),
                  ],
                ),
              ),
              children: [
                NamedRouteDef(
                  name: 'AddDrugTemplateRoute',
                  path: 'add_drug_template_screen',
                  builder: (_, _) => _page('AddDrugTemplateRoute'),
                ),
                NamedRouteDef(
                  name: 'AddCriTemplateRoute',
                  path: 'add_cri_template_screen',
                  builder: (_, _) => _page('AddCriTemplateRoute'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);

    unawaited(router.navigatePath('/home_screen/drug_database_screen/add_drug_template_screen'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('AddDrugTemplateRoute'), findsOneWidget);
    expect(router.urlState.url, '/home_screen/drug_database_screen/add_drug_template_screen');

    unawaited(router.pushPath('/home_screen/drug_database_screen/add_cri_template_screen'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('AddCriTemplateRoute'), findsOneWidget);
    expect(router.urlState.url, '/home_screen/drug_database_screen/add_cri_template_screen');
  });
}

Widget _page(String text) => Scaffold(body: Text(text));
