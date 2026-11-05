import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// replace() with the route that is open, changing only its child's path
// param, shows the new page.
// https://github.com/Milad-Akarie/auto_route_library/issues/1112
// Headless test: auto_route/test/pool_a5/path_param_only_change_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('replace changed path param', () {
    // Steps: open /quiz/1, whose page holds a nested router, then replace the
    // route with the same one holding quiz 2.
    // Should: quiz 2 shows, in the page and in the url.
    testWidgets(
      'replace with another path param in a nested route shows the new page '
      '(#1112)',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            NamedRouteDef(
              name: 'QuizHostRoute',
              path: '/quiz',
              builder: (_, _) => const AutoRouter(),
              children: [
                NamedRouteDef(
                  name: 'QuizRoute',
                  path: ':id',
                  builder: (context, data) => Scaffold(
                    body: SafeArea(
                      child: Text(
                        'Quiz ${data.inheritedPathParams.getString('id')}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        await pumpRouterApp(tester, router, initialLink: '/quiz/1');
        expect(find.text('Quiz 1'), findsOneWidget);

        unawaited(
          router.replace(
            const NamedRoute(
              'QuizHostRoute',
              children: [
                NamedRoute('QuizRoute', params: {'id': '2'}),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Quiz 2'), findsOneWidget);
        expect(find.text('Quiz 1'), findsNothing);
        expect(router.currentUrl, '/quiz/2');
      },
    );
  });
}
