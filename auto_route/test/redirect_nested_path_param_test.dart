import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1231
// Setup: RedirectRoute(path: '/two/:slug', redirectTo:
// '/tabs/two/:slug'), where '/tabs' is a page with the children 'one' and 'two/:slug'.
// Steps: open the link '/two/0', with and without a guard on '/tabs'.
// Should: the url is '/tabs/two/0', not '/tabs/two/0/two/0', and the page
// reads slug 0.
void main() {
  for (final guarded in [false, true]) {
    testWidgets(
      'A redirect with a path param to a nested child keeps one url, guarded: $guarded',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            RedirectRoute(path: '/', redirectTo: '/tabs'),
            RedirectRoute(path: '/two/:slug', redirectTo: '/tabs/two/:slug'),
            AutoRoute(
              path: '/tabs',
              page: PageInfo('TabsRoute', builder: (_) => const AutoRouter()),
              guards: [
                if (guarded)
                  AutoRouteGuard.simple((resolver, _) => resolver.next()),
              ],
              children: [
                AutoRoute(
                  path: 'one',
                  page: PageInfo('OneRoute', builder: (_) => const Text('One')),
                  initial: true,
                ),
                AutoRoute(
                  path: 'two/:slug',
                  page: PageInfo(
                    'TwoRoute',
                    builder: (data) =>
                        Text('Two ${data.params.getString('slug')}'),
                  ),
                ),
              ],
            ),
          ],
        );
        await pumpRouterApp(tester, router, initialLink: '/two/0');
        expect(find.text('Two 0'), findsOneWidget);
        expect(router.urlState.url, '/tabs/two/0');
      },
    );
  }
}
