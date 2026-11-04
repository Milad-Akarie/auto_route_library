import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// A page that reads its route data in build is not built again when a dialog
// opens over it.
// The same scenario as flutter/flutter#164566 in go_router, where
// GoRouterState.of rebuilt the page when a dialog opened.
void main() {
  final reads = <String, Object? Function(BuildContext)>{
    'RouteData.of': RouteData.of,
    'context.routeData': (context) => context.routeData,
    'context.router': (context) => context.router,
    'AutoRouter.of': AutoRouter.of,
  };

  for (final MapEntry(key: name, value: read) in reads.entries) {
    // Steps: HomeRoute's build calls $name; open showAboutDialog, then close
    // it. Should: HomeRoute is built once, before and after.
    testWidgets('a page that calls $name in build is not rebuilt by a dialog', (tester) async {
      var builds = 0;
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => Builder(
                builder: (context) {
                  builds++;
                  read(context);
                  return const Text('HomeRoute');
                },
              ),
            ),
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      expect(builds, 1);

      showAboutDialog(context: router.navigatorKey.currentContext!, applicationName: 'Sample');
      await tester.pumpAndSettle();
      expect(find.byType(AboutDialog), findsOneWidget);
      expect(builds, 1);

      router.navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AboutDialog), findsNothing);
      expect(builds, 1);
    });
  }
}
